# ConnectEd Monitoring

## Do these things once

1. Open an R session and install the necessary packages.

    ```r
    install.packages('pak')
    pak::pak()
    ```

1. Create a text file called "scto_auth.txt" in the params folder and add the SurveyCTO server name on the first line, username on the second line, and password on the third line.

1. Open a Terminal session in the main connected_monitoring folder and run the script to process the call assignments.

    ```sh
    Rscript code/get_call_assignments.R
    ```

## Do these things each week

1. Open a Terminal session in the main connected_monitoring folder and run the monitoring script.

    ```sh
    Rscript code/get_monitoring.R
    ```

1. Examine the resulting files in the output folder.

## To use with GitHub Actions

1. Create a repository secret called "SCTO_AUTH" containing the contents of "scto_auth.txt".

1. Create a repository secret called "GOOGLE_TOKEN" containing the JSON of a Google service account token.

1. In the relevant Google Sheet, give editor permissions to the email address of the corresponding Google service account (e.g., xx@yy.iam.gserviceaccount.com).
