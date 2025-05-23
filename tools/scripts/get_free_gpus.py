import warnings, json, subprocess, concurrent.futures
from typing import Dict
from scripts.constants import CLUSTERS

# Suppress cryptography deprecation warnings
warnings.filterwarnings('ignore')

try:
    from beaker import Beaker
except ImportError:
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "beaker-py"])

# Attempt to install rich if it doesnt exist
try:
    import rich
except ImportError:
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rich"])

from rich.console import Console
from rich.table import Table


def get_cluster_free_gpus(cluster) -> Dict[str, int]:
    """Get free GPU count for a single cluster"""
    try:
        # Run beaker CLI command to get free slots
        cmd = ["beaker", "cluster", "free-slots", cluster, "--format", "json"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Parse JSON output
            slots_data = json.loads(result.stdout)
            
            # Handle empty list case
            if not slots_data:
                return {cluster: 0}
            
            # Sum available slots across all nodes
            total_free_gpus = sum(node["availableSlots"] for node in slots_data)
            
            return {cluster: total_free_gpus}
                
    except Exception as e:
        console = Console()
        console.print(f"Failed to get free slots for cluster {cluster}: {e}", style="red")
    
    return {}

def get_free_gpus():
    # Get all clusters for the default organization
    # beaker = Beaker.from_env()
    # cluster_client = beaker.cluster
    # clusters = cluster_client.list()
    # clusters = [cluster.full_name for cluster in clusters]

    # Filter to only the clusters we care about from CLUSTERS constant
    clusters = set()
    for _, cluster_list, _, _ in CLUSTERS:
        if not isinstance(cluster_list, list): cluster_list = [cluster_list]
        clusters.update(cluster_list)
    clusters = sorted(list(clusters))

    free_gpus = {}
    
    # Use beaker API to get free GPUs on all clusters
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_to_cluster = {executor.submit(get_cluster_free_gpus, cluster): cluster 
                           for cluster in clusters}
        
        for future in concurrent.futures.as_completed(future_to_cluster):
            free_gpus.update(future.result())
            
    return free_gpus

if __name__ == '__main__':
    # Usage example:
    free_gpus = get_free_gpus()

    console = Console()
    table = Table(header_style="bold", box=None)
    table.add_column("Cluster")
    table.add_column("Free GPUs", justify="right")

    for cluster_name, gpu_count in free_gpus.items():
        table.add_row(cluster_name, str(gpu_count))

    console.print(table)