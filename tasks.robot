*** Settings ***
Documentation       Ask the user to input the url for the order.csv file
...                 Runs the orders from the order.csv through the build-a-robot website.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc.
    ${result.url_input}=    Ask user for URL
    Download Orders    ${result.url_input}
    Open the robot order website
    Get Orders
    Submit Orders


*** Keywords ***
Ask user for URL
    Add text input    url_input    Order URL
    ${result}=    Run dialog
    RETURN    ${result.url_input}

Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser    ${secret}[url]

Download Orders
    [Arguments]    ${result.url_input}
    Download    ${result.url_input}    overwrite=true

Get Orders
    ${orders}=    Read table from CSV    orders.csv    header=true
    RETURN    @{orders}

Submit Orders
    Close the annoying modal
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Fill the form    ${row}
        Preview the Robot
        Wait Until Keyword Succeeds    30    .5    Submit the Order
        Grab receipt info    ${row}
        Screenshot Robot    ${row}
        Embed PDF    ${row}
        Click Button When Visible    order-another
        Close the annoying modal
    END
    Create ZIP Package of Orders
    [Teardown]    Close PDF and Browser

Close the annoying modal
    Click Button When Visible    css:.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    id=address    ${row}[Address]

Preview the Robot
    Click Button    preview

Submit the Order
    Click Button    order
    Wait Until Element Is Visible    receipt    5 seconds

Grab receipt info
    [Arguments]    ${row}
    ${receipt}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}${row}[Order number].pdf

Screenshot Robot
    [Arguments]    ${row}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}robot-preview-image${/}${row}[Order number].png

Embed PDF
    [Arguments]    ${row}
    Open Pdf    ${OUTPUT_DIR}${/}receipts${/}${row}[Order number].pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}robot-preview-image${/}${row}[Order number].png
    ...    ${OUTPUT_DIR}${/}receipts${/}${row}[Order number].pdf

Create ZIP Package of Orders
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Close PDF and Browser
    Close All Pdfs
    Close Browser
