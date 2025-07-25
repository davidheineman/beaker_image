import argparse, sys, warnings

# Suppress cryptography deprecation warnings
warnings.filterwarnings('ignore')

try:
    from beaker import Beaker
except ImportError:
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "beaker-py"])

from beaker import Beaker
from beaker.exceptions import JobNotFound


def stream_experiment_logs(job_id: str, do_stream: bool, return_logs: bool = False):
    # Initialize the Beaker client
    beaker = Beaker.from_env()
    
    try:
        job = beaker.job.get(job_id)

        # Get the experiment ID from the job
        if job.execution is not None:
            experiment_id = job.execution.experiment
        else:
            if job.kind == 'session':
                raise ValueError('Job is a session. Please provide an execution job.')
            raise RuntimeError(job)
    except JobNotFound:
        print(f'Job {job_id} not found, using {job_id} as an experiment ID...')
        experiment_id = job_id

    # Check if there's multiple tasks
    experiment = beaker.experiment.get(experiment_id)
    task_ids = [job.execution.task for job in experiment.jobs]
    if len(task_ids) > 1:
        task_id = next(job.execution.task for job in experiment.jobs if job.execution.replica_rank == 0)
        print(f'Multiple tasks found! Following replica=0: "{task_id}"...')
    else:
        task_id = task_ids[0]
    
    try:
        if do_stream:
            for line in beaker.experiment.follow(
                experiment=experiment_id,
                task=task_id,
                strict=True,
                # since=timedelta(minutes=2)
            ):
                log_line = line.decode('utf-8', errors='replace').rstrip()
                print(log_line)
                sys.stdout.flush()
        else:
            log_stream = beaker.experiment.logs(
                experiment_id, 
                quiet=True,
                # since=timedelta(minutes=2)
            )
            
            logs = ""
            for line in log_stream:
                logs += line.decode('utf-8', errors='replace').rstrip()
                logs += '\n'

            if return_logs:
                return logs

            print(logs)
            sys.stdout.flush()
            
    except KeyboardInterrupt:
        print("\nLog streaming interrupted by user")
    except Exception as e:
        print(f"Error streaming logs: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Stream logs from a Beaker job")
    parser.add_argument("-j", "--job_id", help="The ID or name of the Beaker job", required=True)    
    parser.add_argument("-s", "--stream", help="The ID or name of the Beaker job", action="store_true", default=False)    
    
    args = parser.parse_args()
    
    stream_experiment_logs(args.job_id, do_stream=args.stream)