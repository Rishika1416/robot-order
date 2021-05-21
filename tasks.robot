*** Settings ***
Documentation   Template robot main suite.
Library         RPA.Browser
Library         RPA.HTTP
Library         RPA.Dialogs
Library         RPA.Excel.Files
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Robocloud.Secrets


***Variables***
#${URL}  https://robotsparebinindustries.com/#/
@{int}    Create List	${1}	${2}	${3}
${res}    False

*** Keywords ***
Open the robot order website
  ${URL_secret}   Get secret   Website_url
  Log   ${URL_secret}[URL]
  Open Available Browser  ${URL_secret}[URL]
  Click Link               xpath=//*[@id="root"]/header/div/ul/li[2]/a

*** Keywords ***
Fill the form
    [Arguments]     ${row}
    Log     ${row}
    ${head_as_string}=    BuiltIn.Convert To String    ${row}[Head]
    Select From List By Value   xpath=//*[@id="head"]    ${head_as_string}
    Click Element When Visible     xpath=//*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/label
    Input Text   class:form-control   ${row}[Legs]
    Click Element When Visible  id:id-body-${row}[Body]
    Input Text    xpath=//*[@id="address"]    ${row}[Address]
    BuiltIn.sleep   5s

*** Keywords ***
Download Excel File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

*** Keywords ***
Collect File From User
    Create Form    Upload File
    Add File Input    label=Upload the file with order data
    ...    name=fileupload
    ...    element_id=fileupload
    ...    filetypes=*.csv,*.xls;*.xlsx
    &{response}    Request Response
    [Return]    ${response["fileupload"][0]}

*** Keywords ***
Get Orders
    Download Excel File
    BuiltIn.sleep   5s
    ${file_csv}=     Collect File From User
    ${records}=     Read Table From Csv     ${file_csv}
    #C:\\Users\\Ricky\\Downloads\\orders.csv
    [Return]   ${records}

*** Keywords ***
Close the annoying modal
    Click Button When Visible   xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

***Keywords***
Store the receipt as a PDF file
    [Arguments]     ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipt-${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipt-${order_number}.pdf

***Keywords***
Preview the robot
    Click Button When Visible     id:preview

***Keywords***
Submit the order
    FOR    ${iter}    IN    @{int}
        BuiltIn.Exit For Loop If  '${res}'=='True'
        Wait And Click Button      xpath=//*[@id="order"]
        ${res}  Is Element Visible  xpath=//*[@id="order-another"]
        BuiltIn.Sleep  2s
    END


***Keywords***
Take a screenshot of the robot
    [Arguments]   ${order_number}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}screenshot-${order_number}.png
    [Return]      ${CURDIR}${/}output${/}screenshot-${order_number}.png

***Keywords***
Go to order another robot
    Wait And Click Button    id:order-another

***Keywords***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}    ${pdf}
    Add Watermark Image To PDF    image_path=${screenshot}    source_path=${pdf}  output_path=${pdf}
    Close Pdf   ${pdf}

***Keywords***
Create a ZIP file of the receipts
    Archive Folder With ZIP   ${CURDIR}${/}output  ${CURDIR}${/}output${/}result.zip   recursive=True  include=*.pdf  exclude=/.png

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=  Get Orders
    Open the robot order website
    FOR    ${order}   IN  @{orders}
          Close the annoying modal
          BuiltIn.Sleep    2s
          Fill the form    ${order}
          BuiltIn.Sleep    1s
          Preview the robot
          Submit the order
          ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
          ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
          Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
          Go to order another robot
    END
    Create a ZIP file of the receipts





