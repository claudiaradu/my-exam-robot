*** Settings ***
Documentation       Documentation    Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${pdf_folder}       ${OUTPUT_DIR}${/}pdf_files


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get and log the author name from a vault
    Open the robot order website
    Download the orders file
    ${orders}=    Read the orders file
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill and submit form for one order    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${pdf}=    Store the order receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Collect the screenshot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${OUTPUT_DIR}${/}${screenshot}.png
        ...    ${pdf_folder}${/}${row}[Order number].pdf
        Order another robot
    END
    Create a Zip File of the Receipts
    Get and log the author name from a vault


*** Keywords ***
Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    orders.csv    overwrite=True

Read the orders file
    Download the orders file
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${row}    IN    @{orders}
        Log    ${row}
    END
    RETURN    ${orders}

Fill and submit form for one order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input.form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Collect the screenshot
    [Arguments]    ${screenshot}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}${screenshot}.png
    RETURN    ${screenshot}

Order another Robot
    Click Button    Order another robot

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]
    Mute Run On Failure    Page Should Contain Element
    Click Button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Store the order receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Wait Until Element Is Visible    //*[@id="receipt"]    1 min
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${full_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    ${receipt_html}    ${full_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${full_pdf_filename}
    Open Pdf    ${full_pdf_filename}
    @{myfiles}=    Create List    ${screenshot}
    Add Files To Pdf    ${myfiles}    ${full_pdf_filename}    ${True}
    Close Pdf

Create a Zip File of the Receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file_name}    recursive=True    include=*.pdf

Get and log the author name from a vault
    ${secret}=    Get Secret    author
    Log    ${secret}[author]
