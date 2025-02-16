from datetime import timedelta
import argparse
import sys
import warnings

# Suppress cryptography deprecation warnings
from cryptography.utils import CryptographyDeprecationWarning
warnings.filterwarnings('ignore', category=CryptographyDeprecationWarning)

from beaker import Beaker

def stream_experiment_logs(job_id: str, do_stream: bool):
    # Initialize the Beaker client
    beaker = Beaker.from_env()
    
    # Get the job first
    job = beaker.job.get(job_id)

    # Get the experiment ID
    if job.execution is not None:
        experiment_id = job.execution.experiment
    else:
        if job.kind == 'session':
            raise ValueError('Job is a session. Please provide an execution job.')
        raise RuntimeError(job)
    
    try:
        if do_stream:
            for line in beaker.experiment.follow(
                experiment_id,
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
            
            for line in log_stream:
                log_line = line.decode('utf-8', errors='replace').rstrip()
                print(log_line)
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