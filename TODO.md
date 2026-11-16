Global Function Parameter Management

Objective

Provide a centralized table in Deal Settings to manage and confirm deal-specific Global Function parameters.

Table Structure

The table shall contain five columns:

1. Parameter Name
2. Function Name
3. Type (Number / Date / Flag / Text)
4. Value
5. Analyst Confirmed (Checkbox)

Business Requirements

1. Flexible Parameters: The same Parameter Name may be used by multiple Global Functions with different Values.
2. Parameter Management: Analysts can add, edit, delete, and confirm parameters for each deal.
3. Unique Identification: Each Function Name + Parameter Name combination shall be unique within a deal.
4. Script Access: Parameters shall be accessible using deal.params["FunctionName"]["ParameterName"].
5. Analyst Confirmation: Each parameter requires analyst confirmation. New or modified entries shall be Unconfirmed until reviewed.
6. Copy Deal Info: All parameter entries shall be copied to the new deal, with confirmation status reset to Unconfirmed.
7. Setup Validation: All parameters must be confirmed before Deal Setup is completed.

Example

Parameter Name	Function Name	Type	Value	Analyst Confirmed
MaxRate	Fa	Number	5	☑
MaxRate	Fb	Number	7	☑
MaxRate	Fc	Number	5	☐
Tolerance	Fa	Number	0.01	☑
Tolerance	Fb	Number	0.05	☐

Script Access

deal.params["Fa"]["MaxRate"]  # 5
deal.params["Fb"]["MaxRate"]  # 7
deal.params["Fc"]["MaxRate"]  # 5
deal.params["Fa"]["Tolerance"]  # 0.01
deal.params["Fb"]["Tolerance"]  # 0.05

Different Global Functions may use the same Parameter Name independently without conflicts.