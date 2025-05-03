# Glimpse Action

A GitHub Action that uploads files to a specific branch and returns their URLs for preview purposes, with versioning support.

## Usage

```yaml
name: Upload Files
on: [push]

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Upload files
        id: upload
        uses: your-username/glimpse-action@v1
        with:
          directory: 'path/to/files'
          branch: 'glimpse'  # Optional, defaults to 'glimpse'
          generations: '5'   # Optional, defaults to 5
          
      - name: Display file URLs
        run: echo "File URLs: ${{ steps.upload.outputs.file_urls }}"
```

## Inputs

- `directory`: The directory containing files to upload (required)
- `branch`: The target branch to upload files to (optional, defaults to 'glimpse')
- `generations`: Number of generations to keep (optional, defaults to 5)

## Outputs

- `file_urls`: Comma-separated list of uploaded file URLs

## Features

- Uploads all files from a specified directory to a target branch
- Organizes files by action run number in `runs/<run_number>` directories
- Maintains versioning by keeping only the specified number of generations
- Automatically removes old generations when the limit is exceeded
- Returns direct URLs to the uploaded files
- Simple Docker-based implementation
- Easy to extend for future features like image diff

## File Structure

Files are organized in the following structure:
```
glimpse/
└── runs/
    ├── 1/
    │   └── [your files]
    ├── 2/
    │   └── [your files]
    └── 3/
        └── [your files]
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 