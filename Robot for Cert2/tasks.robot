# -*- coding: utf-8 -*-
*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library           RPA.Dialogs
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocloud.Secrets


*** Keywords ***
Open The Intranet Website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Get orders
    ${secret}=    Get Secret    credentials
    Download    ${secret}[linkforsite]    overwrite=True    
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read Table From Csv    orders.csv    header=true
    [Return]    ${orders}

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Wait Until Page Contains Element    head
    Select From List By Index     head      ${row}[Head]
    ${elementName}=    Catenate    SEPARATOR=   id-body-   ${row}[Body]
    Click Element    ${elementName}
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    Address123

*** Keywords ***
Preview the robot
    Click Button    Preview
    Wait Until Element Is Visible    robot-preview-image
    Wait Until Element Is Visible    xpath://div[@id="robot-preview-image"]/img[@alt="Head"]
    Wait Until Element Is Visible    xpath://div[@id="robot-preview-image"]/img[@alt="Body"]
    Wait Until Element Is Visible    xpath://div[@id="robot-preview-image"]/img[@alt="Legs"]

*** Keyword ***
Close the annoying modal
    Click Button    OK

*** Keyword ***
Take a screenshot of the robot
    [Arguments]    ${orderNr}
    ${pic_name}=    Catenate    SEPARATOR=   ${CURDIR}${/}output${/}    ${orderNr}    .png
    Screenshot    robot-preview-image    ${pic_name}
    [Return]    ${pic_name}

*** Keyword ***
Submit the order
    Wait Until Keyword Succeeds    5x    0.5s    Sub-Submit the order

*** Keyword ***
Sub-Submit the order
    Click Button    id:order
    Wait Until Element Is Not Visible    id:order

*** Keyword ***
Go to order another robot
    Click Button    order-another

*** Keyword ***
Store the receipt as a PDF file
    [Arguments]    ${orderNr}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    #${receipt}=    Catenate    SEPARATOR=    ${receipt}    <br><br><p style="text-align:center;"><img src="     ${CURDIR}${/}output${/}    1.png"></p>
    ${pdf_file}=    Catenate    SEPARATOR=   ${CURDIR}${/}output${/}    ${orderNr}    .pdf
    Html To Pdf    ${receipt}    ${pdf_file}
    [Return]    ${pdf_file}

*** Keyword ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open PDF    ${pdf}
    ${png_file}=    Catenate    SEPARATOR=   ${screenshot}    :align=center
    ${lista}=    Create List
    ...    ${pdf}
    ...    ${png_file}
    Add files to pdf    ${lista}    ${pdf}
    # I will be really curious if somebody will read this. :)
    # The case is, when adding files to pdf (add files to pdf) append does not work as a parameter.
    # Even though it does not matter, I put the original PDF into the list...
    Close Pdf    ${pdf}

*** Keyword ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}    receipts.zip    include=*.pdf

*** Keyword ***
Log Out And Close The Browser
    Close Browser

*** Keywords ***
Show Me an Interactive Superb Dialog
    Add icon      Warning
    Add heading   I am in a dire need of working. Shall I start?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    ${answer}=    Set Variable    ${result.submit}
    [Return]    ${answer}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${answer}=    Show Me an Interactive Superb Dialog
    IF    "${answer}" == "Yes"
        Open The Intranet Website
        ${orders}=    Get orders
        FOR    ${row}    IN    @{orders}
            Close the annoying modal
            Fill the form    ${row}
            Preview the robot
            Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Go to order another robot
        END
        Create a ZIP file of the receipts
    END
    [Teardown]    Log Out And Close The Browser
