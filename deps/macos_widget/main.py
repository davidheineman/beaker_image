import logging
import rumps

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from get_free_gpus import get_free_gpus
from get_jobs import get_job_data

logging.basicConfig(
    filename='/tmp/widget.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logging.debug("Starting application")

OPEN_BL_COMMAND = """
osascript -e 'tell application "Terminal"
    set newWindow to do script "bl"
    set bounds of front window to {100, 100, 900, 600} -- {left, top, right, bottom}
end tell'
"""

OPEN_CHROME_COMMAND = 'open -a "Google Chrome" https://beaker.allen.ai/'

class GPUMonitorApp(rumps.App):
    def __init__(self):
        super(GPUMonitorApp, self).__init__("...")
        self.menu = [
            rumps.MenuItem("♻️ Refresh", callback=self.refresh),
            rumps.MenuItem("🚀 beaker.allen.ai", callback=self.open_beaker),
            None,  # This creates a separator in rumps
        ]
        # Update every 5 minutes (300 seconds)
        self.timer = rumps.Timer(self.update_gpu_info, 300)
        self.timer.start()
        self.username = 'davidh'
        self.workspace = 'davidh'
        logging.debug("App initialized")

    @rumps.clicked("Refresh")
    def refresh(self, _):
        self.title = '...'
        self.update_gpu_info(None)

    @rumps.clicked("beaker.allen.ai") 
    def open_beaker(self, _):
        os.system(OPEN_CHROME_COMMAND)

    def open_bl(self, _):
        os.system(OPEN_BL_COMMAND)

    def dummy(self, _):
        return ""

    def open_workload(self, sender):
        # Extract workload ID from sender's represented_object
        id, workload = sender.represented_object
        if workload:
            url = f"https://beaker.allen.ai/orgs/ai2/workspaces/{self.workspace}/work/{workload}?jobId={id}"
            os.system(f'open -a "Google Chrome" "{url}"')

    def update_gpu_info(self, _):
        try:
            free_gpus = get_free_gpus()

            print(free_gpus)

            # Update the title with a summary
            total_gpus = sum(free_gpus.values())

            title = f"{total_gpus} GPUs"
            self.title = title
            
            # Clear existing menu items (except Refresh and beaker.allen.ai)
            menu_items = list(self.menu)[3:]  # Skip the first two items
            for item in menu_items:
                self.menu.pop(item)

            self.menu.add(rumps.MenuItem('Clusters'))
            for k, v in sorted(free_gpus.items(), key=lambda x: x[1], reverse=True):
                menu_item = rumps.MenuItem(f"{v} GPUs: {k}", callback=self.open_bl)
                self.menu.add(menu_item)

            # Add sep
            self.menu.add(None)

            processed_jobs = get_job_data(
                username=self.username, 
                sessions_only=True
            )
            
            self.menu.add(rumps.MenuItem(f'Jobs for "{self.username}"'))

            total_used_gpus = 0
            for job in processed_jobs:
                hostname = job["hostname"]
                gpus = job["gpus"]
                kind = job["kind"]
                name = job["name"]
                workload = job["workload"]
                id = job["id"]

                total_used_gpus += int(gpus)

                if job["is_canceling"]:
                    continue # just skip these
                elif job["start_date"] is None:
                    job_info = f"[Queued] {kind}: {name}"
                else:
                    job_info = f"{gpus} GPUs {kind}: {name} on {hostname}" # for ongoing jobs

                if len(job_info) > 40:
                    job_info = job_info[:40-3] + "..."
                
                menu_item = rumps.MenuItem(job_info, callback=self.dummy if workload is None else self.open_workload)
                menu_item.represented_object = (id, workload) # Store the workload ID
                self.menu.add(menu_item)

            if total_used_gpus > 0: 
                title += f" ({total_used_gpus})"
            self.title = str(title)

        except Exception as e:
            logging.error(f"Error: {str(e)}", exc_info=True)
            self.title = "ERR"
            self.menu.add(rumps.MenuItem(f"Error: {str(e)}"))

if __name__ == "__main__":
    try:
        GPUMonitorApp().run()
    except Exception as e:
        logging.error(f"Error: {str(e)}", exc_info=True)
        sys.exit(1)