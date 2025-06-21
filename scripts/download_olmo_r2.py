import argparse
import csv
import os
from pathlib import Path
import subprocess
import sys

def download_checkpoint(url, save_dir):
    base_path = Path(save_dir)
    base_path.mkdir(parents=True, exist_ok=True)
    print(f"   -> {base_path}")

    # Common checkpoint files to download
    common_files = [
        "config.yaml",
        "train.pt", 
        "model.safetensors",
        "optim.safetensors"
    ]

    failed_files = []
    for file in common_files:
        source = f"{url.rstrip('/')}/{file}"
        dest = base_path / file

        source = source.replace('https://olmo-checkpoints.org/', 's3://olmo-checkpoints/')
        
        print(f"      -> pulling {file}")
        try:
            cmd = ["s5cmd", "--endpoint-url=https://a198dc34621661a1a66a02d6eb7c4dc3.r2.cloudflarestorage.com/", "cp", "--show-progress", "--concurrency", "100", source, str(dest)]
            print(' '.join(cmd))
            result = subprocess.run(cmd) # capture_output=True, text=True
            
            if result.returncode != 0:
                failed_files.append(file)
                print(f"Failed to download {file}: {result.stderr}")
        except Exception as e:
            failed_files.append(file)
            print(f"Failed to download {file}: {e}")

    if failed_files:
        print(f"\nFAILED to download these files: {failed_files}")

def main():
    """
    Example commands:
    
    aws s3 cp --endpoint-url=https://a198dc34621661a1a66a02d6eb7c4dc3.r2.cloudflarestorage.com/ --recursive s3://olmo-checkpoints/ai2-llm/peteish13/step590000-unsharded /oe-eval-default/ai2-llm/checkpoints/OLMo-medium/peteish13-highlr/step590000-unsharded

    s5cmd --endpoint-url=https://a198dc34621661a1a66a02d6eb7c4dc3.r2.cloudflarestorage.com/ cp "s3://olmo-checkpoints/ai2-llm/peteish13/step590000-unsharded/*" /oe-eval-default/ai2-llm/checkpoints/OLMo-medium/peteish13-highlr/step590000/

    s5cmd --endpoint-url=https://a198dc34621661a1a66a02d6eb7c4dc3.r2.cloudflarestorage.com/ cp s3://olmo-checkpoints/ai2-llm/peteish13/step586000-unsharded/config.yaml /tmp
    """
    parser = argparse.ArgumentParser(description='Download OLMo checkpoints')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    download_parser = subparsers.add_parser('download', 
                                          help='Download checkpoints from CSV file')
    download_parser.add_argument('csv_file', type=str,
                               help='Path to the CSV file containing checkpoint URLs')
    download_parser.add_argument('--steps', type=str, nargs='+', required=True,
                               help='Space-separated list of step numbers to download')
    download_parser.add_argument('--save-dir', type=str, default='./checkpoints',
                               help='Base directory to save downloaded checkpoints')
    list_parser = subparsers.add_parser('list',
                                       help='List available checkpoint steps')
    list_parser.add_argument('csv_file', type=str,
                            help='Path to the CSV file containing checkpoint URLs')
    args = parser.parse_args()

    # Check if s5cmd is available
    if not subprocess.run(['which', 's5cmd'], capture_output=True).returncode == 0:
        print("Error: s5cmd not found. Please install s5cmd first.")
        sys.exit(1)
    
    print(f"Reading CSV file: {args.csv_file}")
    
    with open(args.csv_file, 'r') as f:
        reader = csv.DictReader(f)
        urls = [(row['Step'], row['Checkpoint Directory']) for row in reader]
    
    if args.command == 'list':
        print("Available steps:")
        for step, _ in urls:
            print(f"Step {step}")
        return
    elif args.steps:
        urls = [(step, url) for step, url in urls if step in args.steps]
        if not urls:
            print(f"Error: None of the requested steps {args.steps} found in the CSV file.")
            print("Use list argument to see available checkpoint steps.")
            return
        not_found = set(args.steps) - {step for step, _ in urls}
        if not_found:
            print(f"Warning: Steps not found in CSV: {list(not_found)}")
    
    print(f"Saving checkpoints to: {args.save_dir}")
    for step, url in urls:
        print(f"\nStep {step}:")
        print(f" - {url}")
        save_path = os.path.join(args.save_dir, f"step{step}-unsharded")
        download_checkpoint(url, save_path)

if __name__ == "__main__":
    main()