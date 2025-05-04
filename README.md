# Glimpse Action

<div align="center">

[![Test Glimpse Action](https://github.com/blueswen/glimpse-action/actions/workflows/test.yml/badge.svg)](https://github.com/blueswen/glimpse-action/actions/workflows/test.yml)
[![License](https://img.shields.io/github/license/blueswen/glimpse-action)](LICENSE)

</div>

A GitHub Action that uploads files to a specific branch and returns their URLs for preview purposes, with versioning support.

The image preview feature only works in public repositories.

## Usage

```yaml
name: Upload Files
on: [push]

permissions:
  contents: write  # Required for pushing to branches

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Upload files
        id: upload
        uses: blueswen/glimpse-action@v1
        with:
          directory: 'path/to/files'
          branch: 'glimpse'  # Optional, defaults to 'glimpse'
          generations: '5'   # Optional, defaults to 5

      - name: Display file URLs
        run: |
          echo "File URLs: ${{ steps.upload.outputs.file_urls }}"

      - name: Preview image in summary
        run: |
          echo "## Screenshot URLs" >> $GITHUB_STEP_SUMMARY
          for file_url in $(echo "${{ steps.upload.outputs.file_urls }}" | tr ',' '\n'); do
            filename=$(basename "$file_url")
            echo "![${filename}](${file_url})" >> $GITHUB_STEP_SUMMARY
          done
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

## File Structure

Files are organized in the following structure:

```
/
└── runs/
    ├── 1/
    │   └── [your directory]
    |       └── [your image] 
    ├── 2/
    │   └── [your directory]
    |       └── [your image] 
    ├── 3/
    │   └── [your directory]
    |       └── [your image] 
    ├── 4/
    │   └── [your directory]
    |       └── [your image] 
    └── 5/
        └── [your directory]
            └── [your image] 
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
