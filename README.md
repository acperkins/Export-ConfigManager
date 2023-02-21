# Export-ConfigManager.ps1

This script exports Applications and Task Sequences from System Center Configuration Manager.

XML dumps of each Application and Task Sequence will be saved in the `xml/` directory and these will be automatically checked in to Git.
This provides a record of changes to each over time.

Full exports will be saved in timestamped directories under `exports/` that can be imported later via the Configuration Manager console.
Note that these exports only contain the metadata.
Installation files are not exported by default as this would make the exports significantly larger, but if this is needed simply change `$ExportContent` to `true` near the top of the file.
