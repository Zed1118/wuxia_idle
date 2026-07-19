import tempfile
import unittest
from pathlib import Path

from PIL import Image

import crop_window_content


class CropWindowContentTest(unittest.TestCase):
    def test_crops_titlebar_and_keeps_exact_logical_viewport(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "window.png"
            image = Image.new("RGB", (10, 10), "white")
            for y in range(4, 10):
                for x in range(10):
                    image.putpixel((x, y), (20, 20, 20))
            image.save(path)

            result = crop_window_content.crop_window_content(
                path, logical_width=5, logical_height=3
            )

            self.assertEqual(result["dpr"], 2.0)
            self.assertEqual(result["titlebar_pixels"], 4)
            cropped = Image.open(path).convert("RGB")
            self.assertEqual(cropped.size, (10, 6))
            self.assertEqual(cropped.getpixel((0, 0)), (20, 20, 20))

    def test_rejects_window_smaller_than_requested_content(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "window.png"
            Image.new("RGB", (10, 5), "black").save(path)

            with self.assertRaisesRegex(ValueError, "smaller than requested"):
                crop_window_content.crop_window_content(
                    path, logical_width=5, logical_height=3
                )


if __name__ == "__main__":
    unittest.main()
