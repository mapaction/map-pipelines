::set cy_list=philippines guatemala sri-lanka dominica pakistan vanuatu malawi kenya nepal fiji mali
:: sri-lanka dominica pakistan vanuatu malawi kenya nepal fiji mali
:: set cy_list=bangladesh south-sudan myanmar dominican-republic malawi cameroon sri-lanka indonesia nepal philippines pakistan vanuatu fiji honduras kenya mali dominica
:: set cy_list=philippines guatemala
set cy_list=haiti

for %%g in (%cy_list%) do (
	echo %%g
    set mapchef_event_desc_path="G:\Shared drives\prepared-country-data\%%g\event_description.json"
    D:\MapAction\test_mcd\env27\Scripts\python.exe create_new_country_pipeline.py
	echo %mapchef_event_desc_path%
)

:: D:\MapAction\test_mcd\env27\Scripts\python.exe create_new_country_pipeline.py
