# Examples and Troubleshooting

## Common Errors

### Package Not Found

![Package Manager](images/Fig.38.png)

![Package Import](images/Fig.39.png)

Solution:
```julia
] activate env
add [PACKAGE_NAME]
```

### File Not Found

![Path Configuration](images/Fig.40.png)

![Folder Structure](images/Fig.41.png)

Check all paths in Main.jl are correct.

### Excel Format Error

![Format Error](images/Fig.42.png)

CSV uses commas and dots:

![CSV Format](images/Fig.43.png)

Fix Excel settings:

![Excel Settings](images/Fig.44.png)

![Number Format](images/Fig.45.png)

![Separator Settings](images/Fig.46.png)

Results should be correct:

![Corrected Results](images/Fig.47.png)