import sys
from pathlib import Path

from PIL import Image


def main():
    folder = Path(sys.argv[1])
    output = Path(sys.argv[2])
    views = [Image.open(folder / name).convert("RGB") for name in ("front.png", "left.png", "right.png", "back.png")]
    width, height = views[0].size
    sheet = Image.new("RGB", (width * 2, height * 2), (222, 221, 211))
    for image, position in zip(views, ((0, 0), (width, 0), (0, height), (width, height))):
        sheet.paste(image, position)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=96)
    print(f"TURNAROUND_SHEET_READY path={output} size={sheet.size}")


if __name__ == "__main__":
    main()
