import os


def print_colored(text: str, color_code: int, style_code: str = "") -> None:
    print(f"\033[{style_code}38;5;{color_code}m{text}\033[0m")


def load_gen_lib_color_formats() -> None:
    sample_text = "This is a sample text."
    print_colored(f"Script {os.path.basename(__file__)} run directly, displaying all text colors...\n", 3)

    colors = {
        'd_red': 88, 'red': 1, 'l_red': 9, 'peach': 173, 'orange': 202, 'd_orange': 166, 'l_orange': 208,
        'brown': 94, 'yellow': 11, 'l_yellow': 191, 'd_yellow': 3, 'gold': 58, 'neon': 154,
        'l_green': 10, 'green': 34, 'b_green': 46, 'd_green': 28, 'forrest': 22, 'd_teal': 23,
        'teal': 30, 'l_teal': 43, 'aqua': 50, 'cyan': 51, 'b_blue': 45, 'blue': 33, 'd_blue': 27,
        'l_blue': 12, 'l_purple': 105, 'd_purple': 57, 'purple': 99, 'b_purple': 129, 'lavender': 13,
        'hotpink': 165, 'pink': 212, 'rose': 174, 'd_grey': 239, 'grey': 243, 'l_grey': 248, 'white': 255
    }

    styles = {
        'bold': '1;', 'underline': '4;', 'italics': '3;'
    }

    for color_name, color_code in colors.items():
        print_colored(f"{color_name}: {sample_text}", color_code)

    for style_name, style_code in styles.items():
        print_colored(f"{style_name}: {sample_text}", 255, style_code)


if __name__ == "__main__":
    load_gen_lib_color_formats()