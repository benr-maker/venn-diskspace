# Venn Diskspace Visualization

This application visualizes disk usage with an interactive **drill-down circle packing** diagram.

## Features
- Input box to enter a start directory
- Displays subdirectories as circles sized by file size / count
- Click to drill down into subdirectories
- **Back button** to navigate upward

## Requirements
- Python 3.8+
- Flask
- Gunicorn (optional, for production)

Install requirements:
```bash
pip install -r requirements.txt
```

## Running
```bash
make server
```

Then open [http://127.0.0.1:5000](http://127.0.0.1:5000) in your browser.

## Usage
1. Enter a starting directory in the input box.
2. Circles will appear for subdirectories, with name, file count, and total size.
3. Click a circle to drill down further.
4. Use the **Back button** to return to the parent directory.
