Feature: creating an invoice
  The user won't get any money 
  If they can't
  Create Invoices

  Background:
    Given the user is authenticated with BitPay

  Scenario: The request is correct
    When the user creates an invoice for <price> <currency>
    Then they should recieve an invoice in response for <price> <currency>
    Examples:
      | price    | currency |
      | "5.23" | "USD"    |
      | "10.21" | "EUR"    |

  Scenario: The invoice contains illegal characters
    When the user creates an invoice for <price> <currency>
    Then they will receive an error matching <message>
    Examples:
      | price   | currency | message                              |
      | "5,023" | "USD"    | "Price must be formatted as a float" |
      | "3.21"  | "EaUR"   | "Currency is invalid."               |
      | ""      | "USD"    | "Price must be formatted as a float" |
      | "Ten"   | "USD"    | "Price must be formatted as a float" |
      | "10"    | ""       | "Currency is invalid."               |
