# ConnectEd Monitoring

## Do these things once

1. Open an R session and install the necessary packages.

    ```r
    install.packages(c('data.table', 'glue', 'readxl', 'remotes'))
    remotes::install_github('youth-impact/rsurveycto')
    ```

1. Rename the file "scto_auth_empty.txt" in the params folder to "scto_auth.txt" and add the SurveyCTO server name on the first line, username on the second line, and password on the third line.

1. Open a Terminal session in the main connected_monitoring folder and run the script to process the call assignments.

    ```sh
    Rscript code/get_acct_call_assignments.R
    ```

## Do these things each week

1. Open a Terminal session in the main connected_monitoring folder and run the monitoring script, changing "xx" to the appropriate week number.

    ```sh
    Rscript code/get_monitoring.R xx
    ```

1. Examine the resulting files in the output folder.
