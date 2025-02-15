import textwrap, curses, random, itertools, time, subprocess, threading, queue, sys, os
from figlet import Figlet

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

CLUSTERS = [
    # (pretty name, cluster name, description, default # GPUs)
    (
        "Any CPU  (CPU, 1wk lim, WEKA)",
        [
            "ai2/phobos-cirrascale", 
            "ai2/saturn-cirrascale", 
            "ai2/neptune-cirrascale", 
            "ai2/triton-cirrascale", 
        ],
        "Any cluster supporting 1 week CPU sessions",
        0
    ),
    (
        "Any A100 (80GB A100, 1wk lim, WEKA)", 
        [
            "ai2/saturn-cirrascale", 
        ],
        "Any cluster with 1 week A100 sessions",
        1
    ),
    (
        "Any H100 (80GB H100, 2hr lim, WEKA)", 
        [
            "ai2/ceres-cirrascale", 
            "ai2/jupiter-cirrascale-2", 
        ],
        "Any cluster with 2 hour H100 sessions",
        1
    ),
    (
        "Any GPU  (A100/L40s, 1wk lim, WEKA)",
        [
            "ai2/saturn-cirrascale", 
            "ai2/neptune-cirrascale", 
            "ai2/triton-cirrascale", 
        ],
        "Any cluster with L40s or A100s",
        1
    ),
    (
        "Phobos   (CPU, 1wk lim, WEKA)",       
        "ai2/phobos-cirrascale", 
        "Debugging and data transfers - No GPUs, Ethernet (50 Gbps/server), WEKA storage, 1 week timeout",
        0
    ),
    (
        "Saturn   (80GB A100, 1wk lim, WEKA)", 
        "ai2/saturn-cirrascale", 
        "Small experiments before using Jupiter - 208 NVIDIA A100 (80 GB) GPUs, Ethernet (50 Gbps/server), WEKA storage, 1 week timeout",
        1
    ),
    (
        "Ceres    (80GB H100, 2hr lim, WEKA)", 
        "ai2/ceres-cirrascale", 
        "Small distributed jobs - 88 NVIDIA H100 GPUs (80 GB), 4x NVIDIA InfiniBand (200 Gbps/GPU), WEKA storage, 2 hour timeout",
        1
    ),
    (
        "Jupiter  (80GB H100, 2hr lim, WEKA)", 
        "ai2/jupiter-cirrascale-2", 
        "Large distributed jobs - 1024 NVIDIA H100 (80 GB) GPUs, 8x NVIDIA InfiniBand (400 Gbps/GPU), WEKA storage, 2 hour timeout",
        1
    ),
    (
        "Neptune  (40GB L40s, 1wk lim, WEKA)", 
        "ai2/neptune-cirrascale", 
        "Small experiments (≤ 40 GB memory) - 112 NVIDIA L40 (40 GB) GPUs, Ethernet (50 Gbps/server), WEKA storage, 1 week timeout",
        1
    ),
    (
        "Triton   (40GB L40s, 1wk lim, WEKA)", 
        "ai2/triton-cirrascale", 
        "Session-only - 16 NVIDIA L40 (40 GB) GPUs, Ethernet (50 Gbps/server), WEKA storage, 1 week timeout",
        1
    ),
    (
        "Augusta  (80GB H100, 2hr lim, GCS)",  
        "ai2/augusta-gcp", 
        "Large distributed jobs - 1280 NVIDIA H100 (80 GB) GPUs, TCPXO (200 Gbps/server), Google Cloud Storage, 2 hour timeout",
        1
    ),
]

LAUNCH_COMMAND = """\
beaker session create \
    --name 👋davidh👋 \
    {gpu_command} \
    {cluster_command} \
    --image beaker://davidh/davidh-interactive \
    --workspace ai2/davidh \
    --budget ai2/oe-eval \
    --bare \
    --detach \
    --port 8000 --port 8001 --port 8080 --port 8888 \
    --workdir /oe-eval-default/davidh \
    --mount weka://oe-eval-default=/oe-eval-default \
    --mount weka://oe-training-default=/oe-training-default \
    --mount weka://oe-data-default=/oe-data-default \
    --mount weka://oe-adapt-default=/oe-adapt-default \
    --mount secret://ssh-key=/root/.ssh/id_rsa \
    --mount secret://aws-creds=/root/.aws/credentials \
    --secret-env HF_TOKEN=HF_TOKEN \
    --secret-env OPENAI_API_KEY=OPENAI_API_KEY \
    --secret-env ANTHROPIC_API_KEY=ANTHROPIC_API_KEY \
    --secret-env BEAKER_TOKEN=BEAKER_TOKEN \
    --secret-env WANDB_API_KEY=WANDB_API_KEY \
    -- /usr/sbin/sshd -D\
"""

UPDATE_PORT_CMD = f"source {SCRIPT_DIR}/update_port.sh {{session_id}}"


# this might be a bit much...
QUOTES = [
    "Science is what we understand well enough to explain to a computer. Art is everything else we do. (Knuth, 1995)", # https://www2.math.upenn.edu/~wilf/foreword.pdf
    "Science advances whenever an Art becomes a Science. (Knuth, 1995)",
    "If a machine is expected to be infallible, it cannot also be intelligent. (Turing, 1947)", # https://plato.stanford.edu/entries/turing/
    "I believe that in about fifty years' time it will be possible to programme computers, with a storage capacity of about 10^9, to make them play the imitation game so well that an average interrogator will not have more than 70 per cent chance of making the right identification after five minutes of questioning. (Turing, 1950)",
    "Machines take me bv suprise with great frequency. This is largely because I do not do sufficient calculation to decide what to expect them to do, or rather because, although I do a calculation, I do it in a hurried, slipshod fashion, taking risks. (Turing, 1950)",
    "We offer no explanation as to why these architectures seem to work; we attribute their success, as all else, to divine benevolence. (Shazeer, 2020)",
    "OLMo_θ(x)=softmax(H^L W_O), H^L=f^L∘f^{L-1}∘...∘f^1(E), E=W_Ex + W_Pt, Attn(Q,K,V)=softmax( QK^T / √d_k )V, Q=XW_Q, K=XW_K, V=XW_V, H=concat(H_1, ..., H_h)W_O, H^l = LN(H^{l-1} + Attn(Q,K,V)), Z^l = LN(H^l + FFN(H^l)), FFN(x)=max(0, xW_1+b_1)W_2+b_2, L=-∑ylog(ŷ), θ←θ-η∇L",
    "http://ai.mit.edu/lab/gsb/gsl-archive/gsl95-12dec08.html (I found this on Lilian Lee's website)",
    "Thus we may have knowledge of the past but cannot control it; we may control the future but have no knowledge of it. (Shannon, 1959)", # https://www.gwern.net/docs/cs/1959-shannon.pdf
    "What's the relation between how I think and how I think I think? (Minsky, 1979)",
    "My wife still uses Emacs, which is the most contentious point in our marriage. (Weinberger, 2024)", # https://quotes.cs.cornell.edu
    "Our modest goal is world domination. (Patterson, 2015, describing the RISC-V project)", # https://quotes.cs.cornell.edu/speaker/Dave-Patterson/
    "A picture is worth a thousand words, a video is worth a thousand pictures and a demo a thousand videos. So we're up to, um, ten to the nine. (LeCun, 2004)", # https://quotes.cs.cornell.edu/speaker/Yann--LeCun/
    "Although perhaps of no practical importance, the question is of theoretical interest, and it is hoped that a satisfactory solution of this problem will act as a wedge in attacking other problems of a similar nature and of greater significance. (Shannon on Chess, 1950)", # https://vision.unipv.it/IA1/ProgrammingaComputerforPlayingChess.pdf
]


def send_notification(title, message):
    """ Send a notificaiton on MacOS """
    os.system(f'''osascript -e 'display notification "{message}" with title "{title}"' ''')


class ClusterSelector:
    def __init__(self, max_width=80):
        self.clusters = CLUSTERS
        self.current_selection = 0
        self.figlet = Figlet()
        self.max_width = max_width
        fonts = ["rozzo"]
        random.shuffle(fonts)
        self.figlet.setFont(font=fonts[0])
        self.bg_color = curses.COLOR_BLACK
        try:
            import darkdetect # pip install darkdetect
            self.is_dark_mode = darkdetect.isDark()
        except ImportError:
            self.is_dark_mode = False

    def setup_colors(self):
        # Define colors based on theme
        self.bg_color = curses.COLOR_BLACK if self.is_dark_mode else -1
        if not self.is_dark_mode:
            curses.use_default_colors()

        # Set up color pairs
        curses.init_pair(1, curses.COLOR_GREEN, self.bg_color)     # Regular text
        curses.init_pair(2, curses.COLOR_MAGENTA, self.bg_color)   # Headers/controls
        curses.init_pair(3, curses.COLOR_MAGENTA, self.bg_color)   # Borders
        curses.init_pair(4, curses.COLOR_MAGENTA, self.bg_color)   # Selected item
        curses.init_pair(5, curses.COLOR_MAGENTA, self.bg_color)   # ASCII art

    def draw_ascii_header(self, window):
        max_y, max_x = window.getmaxyx()

        header = self.figlet.renderText('BEAKER')
        
        # Calculate the width of the ASCII art for centering
        lines = header.split('\n')
        max_width = max(len(line.rstrip()) for line in lines)
        x_offset = (max_x - max_width) // 2
        
        y = 1
        for line in lines:
            if line.strip():
                try:
                    window.addstr(y, x_offset, line.rstrip(), curses.color_pair(5))
                except curses.error:
                    pass
                y += 1
        return y + 1

    def draw_menu(self, window, start_y: int):
        # Get window dimensions
        max_y, max_x = window.getmaxyx()
        # Use the smaller of max_width or actual terminal width
        display_width = min(self.max_width, max_x)
        
        # Calculate left offset to center everything
        left_offset = (max_x - display_width) // 2
        
        # Center the text based on display width
        window.addstr(
            start_y, 
            left_offset, 
            "Select a Cluster (https://beaker-docs.apps.allenai.org/compute/clusters.html)".center(display_width), 
            curses.color_pair(2) | curses.A_BOLD
        )
        window.addstr(start_y + 1, left_offset, "=" * display_width, curses.color_pair(2))
        
        # Calculate menu dimensions using display width
        menu_width = display_width // 2 - 2
        
        # Draw the menu box
        for y in range(start_y + 2, max_y - 2):
            window.addstr(y, left_offset, "│" + " " * menu_width + "│", curses.color_pair(3))
        window.addstr(start_y + 2, left_offset, "┌" + "─" * menu_width + "┐", curses.color_pair(3))
        window.addstr(max_y - 2, left_offset, "└" + "─" * menu_width + "┘", curses.color_pair(3))

        # Draw the description box
        desc_x = left_offset + menu_width + 2
        for y in range(start_y + 2, max_y - 2):
            window.addstr(y, desc_x, "│" + " " * menu_width + "│", curses.color_pair(3))
        window.addstr(start_y + 2, desc_x, "┌" + "─" * menu_width + "┐", curses.color_pair(3))
        window.addstr(max_y - 2, desc_x, "└" + "─" * menu_width + "┘", curses.color_pair(3))

        # Draw the clusters
        for idx, (cluster, _, _, _) in enumerate(self.clusters):
            style = curses.color_pair(4) | curses.A_BOLD if idx == self.current_selection else curses.color_pair(1)
            window.addstr(start_y + 3 + idx, left_offset + 2, f"{'●' if idx == self.current_selection else '○'} {cluster}", style)

        # Draw the description
        _, _, description, _ = self.clusters[self.current_selection]
        desc_lines = textwrap.wrap(description, width=menu_width - 4)
        for idx, line in enumerate(desc_lines):
            window.addstr(start_y + 3 + idx, desc_x + 2, line, curses.color_pair(1))

        # Update the controls text to show number key option
        controls = "select [tab] | navigate [up / down] | press [1-8] for GPUs | [q]uit | [t]oggle theme"
        window.addstr(max_y - 1, left_offset, controls.center(display_width), curses.color_pair(2))

    def draw_process_output(self, window, cluster_name: str, num_gpus: int):
        max_y, max_x = window.getmaxyx()
        menu_width = max_x // 2 - 4
        
        # Clear screen but keep header
        window.clear()
        header_height = self.draw_ascii_header(window)

        # Center the text based on display width
        max_y, max_x = window.getmaxyx()
        display_width = max_x - 5
        
        # Wrap the quote text
        quote = random.choice(QUOTES)
        wrapped_quote = textwrap.wrap(quote, width=display_width)
        
        # Display each line of the wrapped quote
        for i, line in enumerate(wrapped_quote):
            window.addstr(
                header_height + i, 
                3, 
                line, 
                curses.color_pair(2) | curses.A_ITALIC
            )
        header_height += len(wrapped_quote)
        
        # Draw the output box
        box_width = max_x - 6
        box_height = max_y - header_height - 2
        
        # Draw box borders
        window.addstr(header_height, 2, "┌" + "─" * box_width + "┐", curses.color_pair(3))
        for y in range(header_height + 1, header_height + box_height):
            window.addstr(y, 2, "│" + " " * box_width + "│", curses.color_pair(3))
        window.addstr(header_height + box_height, 2, "└" + "─" * box_width + "┘", curses.color_pair(3))
        
        # Draw quick start command
        if not isinstance(cluster_name, list): cluster_name = [cluster_name]
        gpu_flag = f" -g {num_gpus}" if num_gpus > 0 else ""
        quick_start = f"blaunch -c {' '.join(cluster_name)}{gpu_flag}"
        window.addstr(header_height + 1, 4, f"Quick start command: {quick_start}", curses.color_pair(2) | curses.A_BOLD)

        # Draw title (moved down by 5 lines to add more spacing)
        try:
            tailscale_output = subprocess.check_output(['tailscale', 'status'], stderr=subprocess.STDOUT, text=True)
            if "failed to connect to local Tailscale service" in tailscale_output:
                raise subprocess.CalledProcessError(1, 'tailscale status')
        except subprocess.CalledProcessError:
            window.addstr(header_height + 2, 4, "Error: Tailscale service is not running!", curses.color_pair(1))
            window.addstr(max_y - 1, 2, "Press any key to continue...", curses.color_pair(2))
            window.refresh()
            window.getch()
            return False

        gpu_command = ""
        if num_gpus > 0:
            gpu_command = f"--gpus {num_gpus}"  # Use the selected number of GPUs

        cluster_command = ""
        for _cluster_name in cluster_name:
            cluster_command += f"--cluster {_cluster_name} "

        command = LAUNCH_COMMAND.format(gpu_command=gpu_command, cluster_command=cluster_command)
        command = command.replace('  ', ' ')

        output_queue = queue.Queue()
        spinner = itertools.cycle(['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'])
        last_spin_time = time.time()

        process = subprocess.Popen(
            command.split(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            bufsize=1
        )

        def enqueue_output(out, queue):
            for line in iter(out.readline, ''):
                queue.put(line)
            out.close()

        # Start threads to read stdout and stderr
        threading.Thread(target=enqueue_output, args=(process.stdout, output_queue), daemon=True).start()
        threading.Thread(target=enqueue_output, args=(process.stderr, output_queue), daemon=True).start()

        # Display output
        lines = []
        max_lines = box_height - 4  # Leave room for header and borders
        line_pos = header_height + 2
        last_line_count = 0

        window.nodelay(1)  # Make getch non-blocking
        
        while process.poll() is None or not output_queue.empty():
            try:
                line = output_queue.get_nowait()
                lines.append(line.strip())
                if len(lines) > max_lines:
                    lines.pop(0)
                
                # Only update the new line instead of clearing everything
                current_line_count = len(lines)
                display_line = lines[-1]
                try:
                    self.add_colored_str(
                        window,
                        header_height + 2 + min(current_line_count - 1, max_lines - 1),
                        4,
                        display_line[:box_width-6],
                        curses.color_pair(1)
                    )
                except curses.error:
                    pass
                
                # Update spinner every 100ms while process is still running
                current_time = time.time()
                if current_time - last_spin_time > 0.1:
                    try:
                        if process.poll() is None:  # Only show spinner if process is still running
                            window.addstr(max_y-3, 4, f"{next(spinner)} Launching session...", curses.color_pair(2))
                        else:
                            window.addstr(max_y-3, 4, "✓ Session launched!", curses.color_pair(2))
                        last_spin_time = current_time
                    except curses.error:
                        pass
                
                window.refresh()
            except queue.Empty:
                # Update spinner even when there's no output
                current_time = time.time()
                if current_time - last_spin_time > 0.1:
                    try:
                        window.addstr(max_y-3, 4, f"{next(spinner)} Launching session...", curses.color_pair(2))
                        last_spin_time = current_time
                    except curses.error:
                        pass
                    window.refresh()
                time.sleep(0.01)  # Prevent CPU spinning
            
            # Check for 'q' key press to allow canceling
            try:
                if window.getch() == ord('q'):
                    process.terminate()
                    return None
            except curses.error:
                pass

        window.nodelay(0)  # Reset to blocking mode
        
        # Wait for user to press any key before returning
        window.addstr(max_y-3, 4, "✓ Session launched!    ", curses.color_pair(2))

        # Extract session ID from the output
        session_id = None
        for line in lines:
            if "Starting session" in line:
                session_id = line.split()[2]  # Gets the session ID from "Starting session {id} ..."
                break

        if session_id:
            try:
                # Run the port update script using the same subprocess pattern
                port_process = subprocess.Popen(
                    UPDATE_PORT_CMD.format(session_id=session_id),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True,
                    bufsize=1,
                    shell=True,
                    executable='/bin/zsh'
                )

                # Use the same output handling logic
                port_output_queue = queue.Queue()
                threading.Thread(
                    target=enqueue_output,
                    args=(port_process.stdout, port_output_queue),
                    daemon=True
                ).start()
                threading.Thread(
                    target=enqueue_output,
                    args=(port_process.stderr, port_output_queue),
                    daemon=True
                ).start()

                # Continue with existing lines instead of starting fresh
                port_lines = lines  # Use the existing lines from the previous process
                max_port_lines = box_height - 4
                spinner = itertools.cycle(['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'])
                last_spin_time = time.time()

                window.nodelay(1)  # Make getch non-blocking

                while port_process.poll() is None or not port_output_queue.empty():
                    try:
                        line = port_output_queue.get_nowait()
                        port_lines.append(line.strip())
                        if len(port_lines) > max_port_lines:
                            port_lines.pop(0)

                        # Display all visible lines
                        for idx, display_line in enumerate(port_lines[-max_port_lines:]):
                            try:
                                # Clear the line first by writing spaces
                                window.addstr(
                                    header_height + 3 + idx,
                                    4,
                                    " " * (box_width-6),
                                    curses.color_pair(1)
                                )
                                # Then write the new text
                                self.add_colored_str(
                                    window,
                                    header_height + 3 + idx,
                                    4,
                                    display_line[:box_width-6],
                                    curses.color_pair(1)
                                )
                            except curses.error:
                                pass

                        # Update spinner
                        current_time = time.time()
                        if current_time - last_spin_time > 0.1:
                            try:
                                if port_process.poll() is None:
                                    window.addstr(max_y-3, 4, f"{next(spinner)} Updating ports...", curses.color_pair(2))
                                last_spin_time = current_time
                            except curses.error:
                                pass

                        window.refresh()
                    except queue.Empty:
                        # Update spinner even when there's no output
                        current_time = time.time()
                        if current_time - last_spin_time > 0.1:
                            try:
                                window.addstr(max_y-3, 4, f"{next(spinner)} Updating ports...", curses.color_pair(2))
                                last_spin_time = current_time
                            except curses.error:
                                pass
                            window.refresh()
                        time.sleep(0.01)

                    # Check for 'q' key press to allow canceling
                    try:
                        if window.getch() == ord('q'):
                            port_process.terminate()
                            return None
                    except curses.error:
                        pass

                window.nodelay(0)  # Reset to blocking mode

                if port_process.returncode == 0:
                    updated_notif = f'Session launched with {num_gpus} GPUs ({session_id})'
                    window.addstr(
                        max_y-3,
                        4,
                        f"✓ {updated_notif}",
                        curses.color_pair(2)
                    )
                    send_notification("Beaker Launch", updated_notif)
                else:
                    error_notif = f'Port update failed ({session_id})'
                    window.addstr(
                        max_y-3,
                        4,
                        f"! {error_notif}",
                        curses.color_pair(1)
                    )
                    send_notification("Beaker Launch", error_notif)
            except Exception as e:
                error_notif = f"Port update error: {str(e)}"
                window.addstr(
                    max_y-3,
                    4,
                    f"! {error_notif}",
                    curses.color_pair(1)
                )
                send_notification("Beaker Launch", error_notif)

        # Store all output lines for later display
        self.final_output_lines = lines
        
        window.addstr(max_y - 1, 2, "Press any key to continue...", curses.color_pair(2))
        window.refresh()
        window.getch()
        
        return process.returncode == 0

    def run(self, stdscr):
        # Setup colors
        curses.start_color()
        self.setup_colors()
        
        # Set background color based on theme
        if not self.is_dark_mode:
            stdscr.bkgd(' ', curses.color_pair(1))
        
        # Hide the cursor
        curses.curs_set(0)
        
        while True:
            stdscr.clear()
            
            # Draw the interface
            header_height = self.draw_ascii_header(stdscr)
            self.draw_menu(stdscr, header_height)
            
            # Refresh the screen
            stdscr.refresh()
            
            # Handle input
            key = stdscr.getch()
            if key == ord('q'):
                break
            elif key == ord('t'):
                self.is_dark_mode = not self.is_dark_mode
                self.setup_colors()
            elif key == curses.KEY_UP and self.current_selection > 0:
                self.current_selection -= 1
            elif key == curses.KEY_DOWN and self.current_selection < len(self.clusters) - 1:
                self.current_selection += 1
            # Add number key handling
            elif key in [ord(str(i)) for i in range(1, 9)]:  # Handle keys 1-8
                num_gpus = int(chr(key))
                _, cluster_name, _, _ = self.clusters[self.current_selection]
                success = self.draw_process_output(stdscr, cluster_name, num_gpus)
                if success:
                    return self.clusters[self.current_selection][0]
                else:
                    continue
            # Add enter key handling with defaults
            elif key in [ord('\n'), ord(' ')]:
                _, cluster_name, _, default_n_gpus = self.clusters[self.current_selection]
                # Default to 1 GPU for GPU clusters, 0 for CPU clusters
                num_gpus = default_n_gpus
                success = self.draw_process_output(stdscr, cluster_name, num_gpus)
                if success:
                    return self.clusters[self.current_selection][0]
                else:
                    continue

    def parse_ansi_color(self, text):
        # ANSI color code mapping to curses colors
        ansi_to_curses = {
            '30': self.bg_color,
            '31': curses.COLOR_RED,
            '32': curses.COLOR_GREEN,
            '33': curses.COLOR_YELLOW,
            '34': curses.COLOR_BLUE,
            '35': curses.COLOR_MAGENTA,
            '36': curses.COLOR_CYAN,
            '37': curses.COLOR_WHITE,
        }
        
        parts = []
        current_pos = 0
        current_color = None
        
        while True:
            # Find next color code
            esc_pos = text.find('\033[', current_pos)
            if esc_pos == -1:
                # Add remaining text with current color
                if current_pos < len(text):
                    parts.append((text[current_pos:], current_color))
                break
                
            # Add text before escape code
            if esc_pos > current_pos:
                parts.append((text[current_pos:esc_pos], current_color))
                
            # Find end of escape code
            m_pos = text.find('m', esc_pos)
            if m_pos == -1:
                break
                
            # Parse color code
            color_code = text[esc_pos+2:m_pos]
            if color_code == '00':
                current_color = None
            else:
                current_color = ansi_to_curses.get(color_code)
                
            current_pos = m_pos + 1
            
        return parts

    def add_colored_str(self, window, y, x, text, default_color):
        current_x = x
        for text_part, color in self.parse_ansi_color(text):
            try:
                if color is not None:
                    # Create a new color pair for this color if needed
                    pair_num = color + 10  # Offset to avoid conflicts with existing pairs
                    curses.init_pair(pair_num, color, self.bg_color)
                    window.addstr(y, current_x, text_part, curses.color_pair(pair_num))
                else:
                    window.addstr(y, current_x, text_part, default_color)
                current_x += len(text_part)
            except curses.error:
                pass

def main():
    try:
        selector = ClusterSelector(max_width=100)
        selected_cluster = curses.wrapper(selector.run)
        # Print the captured output from both processes
        if selected_cluster:
            # Get the last process's output lines
            if hasattr(selector, 'final_output_lines'):
                for line in selector.final_output_lines:
                    print(line)
    except (KeyboardInterrupt, curses.error):
        sys.exit(0)  # Exit cleanly on Ctrl+C

if __name__ == "__main__":
    # beaker job list --cluster ai2/saturn-cirrascale
    # globe -snc2 -z 1.5
    main()