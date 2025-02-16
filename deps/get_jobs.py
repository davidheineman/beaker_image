import argparse
import warnings

# Suppress cryptography deprecation warnings
from cryptography.utils import CryptographyDeprecationWarning
warnings.filterwarnings('ignore', category=CryptographyDeprecationWarning)

from beaker import Beaker
from beaker.services.job import JobClient
from beaker.data_model.job import JobKind

# Attempt to install rich if it doesnt exist
try:
    from rich.console import Console
    from rich.table import Table
except ImportError:
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rich"])
    from rich.console import Console
    from rich.table import Table


def parse_arguments():
    parser = argparse.ArgumentParser(description='Script to list all running jobs on AI2 through Beaker (for cleaning up those you are done with).')
    parser.add_argument('--username', type=str, required=True, help='The username to process.')
    return parser.parse_args()


def main():
    args = parse_arguments()
    beaker = Beaker.from_env()
    client = JobClient(beaker=beaker)

    jobs = client.list(
        kind=JobKind.session,
        author=args.username,
        finalized=False,
    )

    # Parse job data
    jobs = [{
        "id": job.id,
        "kind": job.kind,
        "name": job.name,
        "start_date": job.status.started,
        "hostname": job.session.env_vars[9].value, # Get hostname from env vars
        "priority": job.session.priority,
        "port_mappings": job.port_mappings,
        "gpus": next((env.value for env in job.session.env_vars if env.name == "BEAKER_ASSIGNED_GPU_COUNT"), "0")
    } for job in jobs]

    console = Console()
    table = Table(header_style="bold white", box=None)

    table.add_column("ID", style="cyan", no_wrap=True)
    table.add_column("Kind", style="magenta")
    table.add_column("Name", style="green")
    table.add_column("Start Date", style="white")
    table.add_column("Hostname", style="blue", overflow="fold")
    table.add_column("Priority", style="blue")
    table.add_column("GPUs", style="magenta")
    table.add_column("Port Mappings", style="white")

    for job in jobs:
        port_map_str = ""
        if job["port_mappings"] is not None:
            port_map_str = " ".join(f"{k}->{v}" for k, v in job["port_mappings"].items())
        table.add_row(
            job["id"],
            job["kind"],
            job["name"],
            job["start_date"].strftime("%Y-%m-%d %H:%M:%S") if job["start_date"] is not None else "[red]Starting...[/red]",
            job["hostname"],
            job["priority"],
            job["gpus"],
            port_map_str,
        )

    console.print(table)

if __name__ == "__main__": main()