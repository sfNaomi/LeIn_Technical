/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class OrderTriggerHandlerTest {
    @TestSetup
    private static void recalculatePermSetGroups() {
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];

        Test.calculatePermissionSetGroup(new Id[]{
            adminPermSetGroup.Id
        });
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ProspectAccountNewOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Prospect', LastOrderDate__c = null)
        );

        // create order
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id));
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception ex) {
            String expectedErrorMessage = Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus;
            Assert.isTrue(ex.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ActiveProspectAccountNewTelesalesOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Active Prospect', LastOrderDate__c = null)
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id));
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception ex) {
            Assert.isTrue(false, 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ActiveProspectAccountNewDraftFieldDirectOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Active Prospect', LastOrderDate__c = null)
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id));
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception ex) {
            Assert.isTrue(false, 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_DpAccountWithNotEnoughAvailableCredit() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create parent account
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                DefaultInvoiceBillingAddress__c = false)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good',
                aforza__Credit_Amount__c = 0, aforza__Default_Price_Book__c = newPricebook.Id, ParentId = parentAccount.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, PaymentMethod__c = 'Direct Debit',
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id,
                Quantity = 10, UnitPrice = 10)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedAccNotEnoughCredit;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_CustomerAccountWithNotEnoughAvailableCredit() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create parent account
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                DefaultInvoiceBillingAddress__c = true, aforza__Credit_Amount__c = 10, CreditStatus__c = 'Good')
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', LastOrderDate__c = null,
                aforza__Default_Price_Book__c = newPricebook.Id, ParentId = parentAccount.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, PaymentMethod__c = 'Direct Debit',
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id,
                Quantity = 10, UnitPrice = 10)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedAccNotEnoughCredit;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_DpAccountOnHold() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'On Hold',
                aforza__Credit_Amount__c = 0, aforza__Default_Price_Book__c = newPricebook.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, PaymentMethod__c = 'Direct Debit',
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false, PreAuthCaptured__c = false)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToAccountOnHold;
            System.debug(e.getMessage());
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_CustomerAccountOnHold() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create parent account
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                aforza__Credit_Amount__c = 0, DefaultInvoiceBillingAddress__c = true, CreditStatus__c = 'On Hold')
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id, ParentId = parentAccount.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, PaymentMethod__c = 'Direct Debit',
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false, PreAuthCaptured__c = false)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToAccountOnHold;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_CheckIfOrderItemGotFullDiscount() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id, aforza__Discount_Percent__c = 100)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedItemFullDiscount;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ECommOrderCardPaymentNoPreAuthNoPaymentAllowedOnInvoiceLevel() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedPreAuthNotCaptured;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_NonECommOrderCardPaymentNoPreAuthNoPaymentAllowedOnInvoiceLevel() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = true);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedPreAuthNotCaptured;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ECommOrderCardPaymentNoPreAuthPaymentAllowedOnInvoiceLevel() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = true);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedPreAuthNotCaptured;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_NonECommOrderCardPaymentNoPreAuthPaymentAllowedOnInvoiceLevel() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedPreAuthNotCaptured;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_NonECommOrderCardPaymentPreAuthCaptured() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as true
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = true
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ECommOrderCardPaymentPreAuthCaptured() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as true
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = true
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_StraightToJDEProductOrderNoPreAuth() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false, Type = 'Product Order'
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedPreAuthNotCaptured;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_StraightToJDEReturnOrderNoPreAuth() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        Order originalOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Receipted', Pricebook2Id = newPricebook.Id, Type = 'Product Order'
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, OriginalOrder__c = originalOrder.Id,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false, Type = 'Return Order'
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error not to be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error not to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_DpAccountNoCreditCashPaymentMethodOnOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Credit_Amount__c = 0, aforza__Default_Price_Book__c = newPricebook.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, PaymentMethod__c = 'Cash')
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to not be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to not be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_DpAccountOnHoldCashPaymentMethodOnOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', LastOrderDate__c = null,
                aforza__Credit_Amount__c = 1000, aforza__Default_Price_Book__c = newPricebook.Id, CreditStatus__c = 'On Hold')
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, PaymentMethod__c = 'Cash')
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to not be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to not be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_CustomerAccountNoCreditCashPaymentMethodOnOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create parent account
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                DefaultInvoiceBillingAddress__c = true, aforza__Credit_Amount__c = 0)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', ParentId = parentAccount.Id,
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, PaymentMethod__c = 'Cash')
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to not be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to not be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_CustomerAccountOnHoldCashPaymentMethodOnOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create parent account
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                DefaultInvoiceBillingAddress__c = true, CreditStatus__c = 'On Hold')
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', LastOrderDate__c = null,
                parentId = parentAccount.Id, aforza__Default_Price_Book__c = newPricebook.Id)
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, PaymentMethod__c = 'Cash')
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error to not be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error to not be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreationOrCompletion_ReturnOrderNoPreAuth() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, CreditStatus__c = 'Good', aforza__Default_Price_Book__c = newPricebook.Id,
                aforza__Credit_Amount__c = 10
            )
        );

        Order originalOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Receipted', Pricebook2Id = newPricebook.Id, Type = 'Product Order'
            )
        );

        // create order with card payment as payment method type and pre authorization as false
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_RETURN_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, IsApproved__c = false, OriginalOrder__c = originalOrder.Id,
                PaymentMethod__c = 'Card Payment', PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = false, PaymentCommerceOnInvoice__c = false);
        insert settings;

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(true, 'Expecting error not to be thrown.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting error not to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateUpdateOfLockedOrders_UserWithEditLockedOrdersPermission() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // create user with "Edit Locked Orders" custom permissions
        User userWithRightToEditLockedOrders;
        System.runAs(runningUser) {
            Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            PermissionSet editLockedOrdersPermission = [SELECT Id FROM PermissionSet WHERE Name = 'EditLockedOrders'];
            userWithRightToEditLockedOrders = (User) TdfSObjectFactory.insertSObject(new User(ProfileId = userProfile.Id));
            TdfSObjectFactory.insertSObject(new PermissionSetAssignment(AssigneeId = userWithRightToEditLockedOrders.Id, PermissionSetId = editLockedOrdersPermission.Id));
        }

        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', LastOrderDate__c = null)
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Receipted',
                IsApproved__c = false, EffectiveDate = System.today()
            )
        );

        System.runAs(userWithRightToEditLockedOrders) {
            Test.startTest();
            try {
                newOrder.EffectiveDate = System.today().addDays(1);
                update newOrder;

                Order updateOrder = [SELECT Id, EffectiveDate FROM Order WHERE Id = :newOrder.Id];
                Assert.areEqual(System.today().addDays(1), updateOrder.EffectiveDate);
            } catch (Exception ex) {
                Assert.isTrue(false, 'Expecting no error to be thrown.');
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testValidateUpdateOfLockedOrders_UserWithoutEditLockedOrdersPermission() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // create user without "Edit Locked Orders" custom permissions
        User userWithoutRightToEditLockedOrders;
        System.runAs(runningUser) {
            Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            userWithoutRightToEditLockedOrders = (User) TdfSObjectFactory.insertSObject(new User(ProfileId = userProfile.Id));
        }

        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Receipted',
                IsApproved__c = false, EffectiveDate = System.today(), OwnerId = userWithoutRightToEditLockedOrders.Id
            )
        );

        System.runAs(userWithoutRightToEditLockedOrders) {
            Test.startTest();
            try {
                newOrder.EffectiveDate = System.today().addDays(1);
                update newOrder;

                Assert.isTrue(false, 'Expecting error to be thrown');
            } catch (Exception ex) {
                String expectedErrorMessage = Label.PreventUpdateOfLockedOrdersErrorMessage;
                Assert.isTrue(ex.getMessage().contains(expectedErrorMessage));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testValidateUpdateOfLockedOrders_SafeUpdateViaService() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // create user without "Edit Locked Orders" custom permissions
        User userWithoutRightToEditLockedOrders;
        System.runAs(runningUser) {
            Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            userWithoutRightToEditLockedOrders = (User) TdfSObjectFactory.insertSObject(new User(ProfileId = userProfile.Id));
        }

        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Receipted',
                IsApproved__c = false, EffectiveDate = System.today(), OwnerId = userWithoutRightToEditLockedOrders.Id
            )
        );

        System.runAs(userWithoutRightToEditLockedOrders) {
            Test.startTest();
            try {
                newOrder.EffectiveDate = System.today().addDays(1);
                OrderService.updateOrdersByPreventingLockValidation(new List<Order>{
                    newOrder
                });

                Order updatedOrder = [SELECT Id, EffectiveDate FROM Order WHERE Id = :newOrder.Id];
                Assert.areEqual(System.today().addDays(1), updatedOrder.EffectiveDate);
            } catch (Exception ex) {
                Assert.isTrue(false, 'Expecting no error to be thrown.');
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCreated() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders', LastOrderDate__c = null
            )
        );

        // create order
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.isNull(updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCompleted() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // complete order
        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.areEqual(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_AtRiskAccountDraftTelesalesOrderIsCompleted() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'At Risk',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // complete order
        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.areEqual(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testPopulateLocalId_LocalIdFilledOnCreation() {
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'At Risk',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, aforza__Local_Id__c = 'Test'
            )
        );
        Test.stopTest();

        Order updatedOrder = [SELECT Id, aforza__Local_Id__c FROM Order WHERE Id = :newOrder.Id];
        Assert.areEqual('Test', updatedOrder.aforza__Local_Id__c);
    }

    @IsTest
    private static void testPopulateLocalId_LocalIdNotFilledOnCreation() {
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'At Risk',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, aforza__Local_Id__c = null
            )
        );
        Test.stopTest();

        Order updatedOrder = [SELECT Id, aforza__Local_Id__c FROM Order WHERE Id = :newOrder.Id];
        Assert.isNotNull(updatedOrder.aforza__Local_Id__c);
    }

    @IsTest
    private static void testCloneCompletedOrder_FieldDirectRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(newOrder.Id, clonedOrder.OriginalOrder__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId = :clonedOrder.Id];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');

        Order updatedOriginalOrder = [SELECT Id, Status FROM Order WHERE Id = :newOrder.Id];
        Assert.areEqual(OrderTriggerHandler.ORDER_STATUS_AFTER_CLONING, updatedOriginalOrder.Status, 'Expecting status of the original order to be updated)');
    }

    @IsTest
    private static void testCloneCompletedOrder_TelesalesRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(newOrder.Id, clonedOrder.OriginalOrder__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId = :clonedOrder.Id];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');

        Order updatedOriginalOrder = [SELECT Id, Status FROM Order WHERE Id = :newOrder.Id];
        Assert.areEqual(OrderTriggerHandler.ORDER_STATUS_AFTER_CLONING, updatedOriginalOrder.Status, 'Expecting status of the original order to be updated)');
    }

    @IsTest
    private static void testCloneCompletedOrder_EcommRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(newOrder.Id, clonedOrder.OriginalOrder__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId = :clonedOrder.Id];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');

        Order updatedOriginalOrder = [SELECT Id, Status FROM Order WHERE Id = :newOrder.Id];
        Assert.areEqual(OrderTriggerHandler.ORDER_STATUS_AFTER_CLONING, updatedOriginalOrder.Status, 'Expecting status of the original order to be updated)');
    }

    @IsTest
    private static void testCloneCompletedOrder_EdiRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(newOrder.Id, clonedOrder.OriginalOrder__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId = :clonedOrder.Id];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');

        Order updatedOriginalOrder = [SELECT Id, Status FROM Order WHERE Id = :newOrder.Id];
        Assert.areEqual(OrderTriggerHandler.ORDER_STATUS_AFTER_CLONING, updatedOriginalOrder.Status, 'Expecting status of the original order to be updated)');
    }

    @IsTest
    private static void testCloneCompletedOrder_ReturnRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        Order originalOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Receipted', Pricebook2Id = newPricebook.Id, Type = 'Product Order'
            )
        );

        // create order and add items to the order
        Order returnOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_RETURN_ID, AccountId = dpAccount.Id, Status = 'Draft',
                Pricebook2Id = newPricebook.Id, OriginalOrder__c = originalOrder.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = returnOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        returnOrder.Status = 'Activated';
        update returnOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(returnOrder.Id, clonedOrder.OriginalOrder__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId = :clonedOrder.Id];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');

        Order updatedOriginalOrder = [SELECT Id, Status FROM Order WHERE Id = :returnOrder.Id];
        Assert.areEqual(OrderTriggerHandler.ORDER_STATUS_AFTER_CLONING, updatedOriginalOrder.Status, 'Expecting status of the original order to be updated)');
    }

    @IsTest
    private static void testCloneCompletedOrder_ValidRecordTypeIncompleteOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = 'Awaiting Approval';
        update newOrder;
        Test.stopTest();

        List<Order> clonedOrder = [SELECT Id, Clone__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(0, clonedOrder.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCloneCompletedOrder_StraightToJdeRecordTypeCompletedOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        List<Order> clonedOrders = [SELECT Id, Clone__c, OriginalOrder__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(0, clonedOrders.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCloneCompletedOrder_InvalidRecordTypeIncompleteOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_VAN_SALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = 'Awaiting Approval';
        update newOrder;
        Test.stopTest();

        List<Order> clonedOrders = [SELECT Id, Clone__c, Status FROM Order WHERE Clone__c = TRUE];
        Assert.areEqual(0, clonedOrders.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCreateInvoice_ValidOrderRecordType() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(1, invoices.size(), 'Expected invoice to be created');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_InvalidOrderRecordType() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_VAN_SALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(0, invoices.size(), 'Expected no invoice to be created');
        Assert.areEqual(0, invoiceLineItems.size(), 'Expected no invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_OrderWithPayment() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create Payment
        aforza__Payment_Transaction__c newPayment = (aforza__Payment_Transaction__c) TdfSObjectFactory.insertSObject(
            new aforza__Payment_Transaction__c(aforza__Account__c = dpAccount.Id, OrderNumber__c = newOrder.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        OrderService.updateOrdersByPreventingLockValidation(new List<Order>{
            newOrder
        });
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(1, invoices.size(), 'Expected invoice to be created');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');

        // retrieve payment and validate result
        List<aforza__Payment_Transaction__c> transactions = [
            SELECT Id, aforza__Invoice__c
            FROM aforza__Payment_Transaction__c
            WHERE Id = :newPayment.Id
        ];
        Assert.areEqual(invoices[0].Id, transactions[0].aforza__Invoice__c, 'Expecting transaction to be linked to invoice');
    }

    @IsTest
    private static void testCreateInvoice_ExistingInvoice() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id, aforza__Credit_Amount__c = 20000
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create Invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(1, invoices.size(), 'Expected existing invoice to be updated');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testPopulateDefaultInventory() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Wednesbury', InventoryCode__c = 'W');
        insert inventory;

        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Depot__c = 'C'));
        Test.stopTest();

        Order order = [SELECT Id, Depot__c, aforza__Inventory__c FROM Order WHERE Id = :newOrder.Id];

        Assert.areEqual('C', order.Depot__c);
        Assert.areEqual(inventory.Id, order.aforza__Inventory__c);
    }

    @IsTest
    private static void testPopulateDefaultInventory_setToNull() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Moston', InventoryCode__c = 'M');
        insert inventory;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Depot__c = 'M'));

        Test.startTest();
        newOrder.Depot__c = null;
        update newOrder;
        Test.stopTest();

        Order order = [SELECT Id, Depot__c, aforza__Inventory__c FROM Order WHERE Id = :newOrder.Id];

        Assert.isNull(order.Depot__c);
        Assert.isNull(order.aforza__Inventory__c);
    }

    @IsTest
    private static void testPopulateLoadWhenAllLInkedOrdersShareStatus() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 5);

        for (Order order : orders) {
            order.Status = 'Pending Delivery';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        Load__c loadUpdated = [SELECT Id, CreateRoute__c FROM Load__c WHERE Id = :load.Id LIMIT 1][0];

        Assert.isTrue(loadUpdated.CreateRoute__c);
    }

    @IsTest
    private static void testPopulateLoadWhenAllLInkedOrdersShareStatus_NotAllChanged() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 5);

        for (Integer i = 0; i < 1; i++) {
            orders[i].Status = 'Pending Delivery';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        Load__c loadUpdated = [SELECT Id, CreateRoute__c FROM Load__c WHERE Id = :load.Id LIMIT 1][0];

        Assert.isFalse(loadUpdated.CreateRoute__c);
    }

    @IsTest
    private static void testRemoveOrdersFromLoad() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Account acc1 = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(AccountId = acc1.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 5);

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Invoice__c(
            aforza__Account__c = acc.Id, aforza__Status__c = 'Outstanding'));
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'));
        orders.add(order);

        for (Integer i = 0; i < orders.size(); i++) {
            orders[i].Status = 'Pending Delivery';
        }

        update orders;

        // check that all data are created as expected
        Assert.areNotEqual(acc1.Id, acc.Id);
        List<aforza__Route_Location__c> routeLocations = [SELECT Id FROM aforza__Route_Location__c];
        Assert.areEqual(2, routeLocations.size());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(2, visits.size());

        List<Task> tasks = [SELECT Id FROM Task];
        Assert.areEqual(7, tasks.size());

        Test.startTest();
        orders[0].Status = 'Unplanned';
        orders[0].Replanned__c = true;
        orders[0].Load__c = null;
        orders[5].Status = 'Unplanned';
        orders[5].Replanned__c = true;
        orders[5].Load__c = null;
        update orders;
        Test.stopTest();

        List<aforza__Route_Location__c> routeLocationAcc1 = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, routeLocationAcc1.size(), 'There should still be route location for this account.');

        List<aforza__Visit__c> visitAcc1 = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, visitAcc1.size(), 'There should still be visit for this account.');

        List<Task> tasksAcc1 = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc1.Id];
        Assert.areEqual(4, tasksAcc1.size(), 'There should be one less task, as one order was removed');

        List<aforza__Route__c> routeAcc = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, routeAcc.size(), 'There should be Route, as not all orders were removed');

        List<Load__c> loadAcc = [SELECT Id FROM Load__c WHERE Id = :load.Id];
        Assert.areEqual(1, loadAcc.size(), 'There should be load, as not all orders were removed');

        List<aforza__Route_Location__c> routeLocationAcc = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(0, routeLocationAcc.size(), 'There should not be any route location as order was removed.');

        List<aforza__Visit__c> visitAcc = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(0, visitAcc.size(), 'There should not be any visit as order was removed.');

        List<Task> tasksAcc = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc.Id];
        Assert.areEqual(0, tasksAcc.size(), 'There should not be any task left for this account, as order was removed');
    }

    @IsTest
    private static void testRemoveOrdersFromLoad_TwoOrdersRemoved() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Account acc1 = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(AccountId = acc1.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 2);

        for (Integer i = 0; i < orders.size(); i++) {
            orders[i].Status = 'Pending Delivery';
        }

        update orders;

        // check that all data are created as expected
        List<aforza__Route_Location__c> routeLocations = [SELECT Id FROM aforza__Route_Location__c];
        Assert.areEqual(1, routeLocations.size());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(1, visits.size());

        List<Task> tasks = [SELECT Id FROM Task];
        Assert.areEqual(2, tasks.size());

        List<aforza__Route__c> route = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, route.size());

        Test.startTest();
        orders[0].Status = 'Unplanned';
        orders[0].Replanned__c = true;
        orders[0].Load__c = null;
        orders[1].Status = 'Unplanned';
        orders[1].Replanned__c = true;
        orders[1].Load__c = null;
        update orders;
        Test.stopTest();

        List<aforza__Route_Location__c> routeLocationAcc = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(0, routeLocationAcc.size(), 'There should not be any route location as order was removed.');

        List<aforza__Visit__c> visitAcc = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(0, visitAcc.size(), 'There should not be any visit as order was removed.');

        List<Task> tasksAcc = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc1.Id];
        Assert.areEqual(0, tasksAcc.size(), 'There should ot be any task left for this account, as order was removed');

        List<aforza__Route__c> routeAcc = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(0, routeAcc.size(), 'There should not be Route anymore, as all orders were removed');

        List<Load__c> loadAcc = [SELECT Id FROM Load__c WHERE Id = :load.Id];
        Assert.areEqual(0, loadAcc.size(), 'There should not be load anymore, as all orders were removed');
    }

    @IsTest
    private static void testCreatePaymentTransactionForDirectDebit() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryPaymentMethod__c = 'Direct Debit')
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, aforza__Account__c = acc.Id)
        );
        Order order = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = acc.Id, PaymentMethod__c = 'Direct Debit', RecordTypeId = RecordTypes.ORDER_EDI_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id));

        Test.startTest();
        order.Status = 'Activated';
        update order;
        Test.stopTest();

        aforza__Payment_Transaction__c pTransaction = [
            SELECT Id, aforza__Status__c, aforza__Type__c
            FROM aforza__Payment_Transaction__c
            WHERE OrderNumber__c = :order.Id
            LIMIT 1
        ];
        Assert.areEqual('Pending', pTransaction.aforza__Status__c);
        Assert.areEqual('Customer Payment', pTransaction.aforza__Type__c);
    }

    @IsTest
    private static void testCreatePaymentTransactionForBacs() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryPaymentMethod__c = 'Bacs')
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_BANK_ACCOUNT_ID, aforza__Account__c = acc.Id)
        );
        Order order = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = acc.Id, PaymentMethod__c = 'Bacs', RecordTypeId = RecordTypes.ORDER_EDI_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id));

        Test.startTest();
        order.Status = 'Activated';
        update order;
        Test.stopTest();

        aforza__Payment_Transaction__c pTransaction = [
            SELECT Id, aforza__Status__c, aforza__Type__c
            FROM aforza__Payment_Transaction__c
            WHERE OrderNumber__c = :order.Id
            LIMIT 1
        ];
        Assert.areEqual('Pending', pTransaction.aforza__Status__c);
        Assert.areEqual('Customer Payment', pTransaction.aforza__Type__c);
    }

    @IsTest
    private static void testCreatePaymentTransactionForJdeDd() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryPaymentMethod__c = 'JDE DD')
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_JDE_DD_ID, aforza__Account__c = acc.Id)
        );
        Order order = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = acc.Id, PaymentMethod__c = 'JDE DD', RecordTypeId = RecordTypes.ORDER_EDI_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id));

        Test.startTest();
        order.Status = 'Activated';
        update order;
        Test.stopTest();

        aforza__Payment_Transaction__c pTransaction = [
            SELECT Id, aforza__Status__c, aforza__Type__c
            FROM aforza__Payment_Transaction__c
            WHERE OrderNumber__c = :order.Id
            LIMIT 1
        ];
        Assert.areEqual('Pending', pTransaction.aforza__Status__c);
        Assert.areEqual('Customer Payment', pTransaction.aforza__Type__c);
    }

    @IsTest
    private static void testOrdersCancellation() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Default_Price_Book__c = newPricebook.Id)
        );

        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );
        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = dpAccount.Id));

        aforza__Payment_Transaction__c newPayment = (aforza__Payment_Transaction__c) TdfSObjectFactory.insertSObject(
            new aforza__Payment_Transaction__c(aforza__Account__c = dpAccount.Id, OrderNumber__c = newOrder.Id)
        );

        //insert BT payment
        TdfSObjectFactory.insertSObject(
            new bt_stripe__Transaction__c(
                bt_stripe__Related_Account__c = dpAccount.Id,
                RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID,
                Order__c = newOrder.Id,
                Invoice__c = invoice.Id
            )
        );

        Test.startTest();
        newOrder.Status = 'Cancelled';
        newOrder.PreAuthCaptured__c = true;
        update newOrder;
        Test.stopTest();

        // retrieve payment and validate result
        Map<Id, aforza__Payment_Transaction__c> transactionsMap = new Map<Id, aforza__Payment_Transaction__c>([
            SELECT Id, aforza__Status__c
            FROM aforza__Payment_Transaction__c
            WHERE OrderNumber__c = :newOrder.Id
        ]);
        Assert.areEqual('Cancelled', transactionsMap.get(newPayment.Id).aforza__Status__c, 'Expecting transaction status to be Cancelled');

        //TODO
        // As we're excluding testing for this
        /*
        // retrieve payment and validate result
        Map<Id, bt_stripe__Transaction__c> btTransactionsMap = new Map<Id, bt_stripe__Transaction__c>([
            SELECT Id, bt_stripe__Refund__c
            FROM bt_stripe__Transaction__c
            WHERE Order__c = :newOrder.Id
        ]);
        Assert.isFalse(btTransactionsMap.get(btNewPayment.Id).bt_stripe__Refund__c, 'Expecting bt-transaction disable for refund');
        */
    }

    @IsTest
    private static void testRemoveOrdersFromLoad_SingleOrdersRemoved() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Account acc1 = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(AccountId = acc1.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 2);

        for (Integer i = 0; i < orders.size(); i++) {
            orders[i].Status = 'Pending Delivery';
        }

        update orders;

        // check that all data are created as expected
        List<aforza__Route_Location__c> routeLocations = [SELECT Id FROM aforza__Route_Location__c];
        Assert.areEqual(1, routeLocations.size());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(1, visits.size());

        List<Task> tasks = [SELECT Id FROM Task];
        Assert.areEqual(2, tasks.size());

        List<aforza__Route__c> route = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, route.size());

        Test.startTest();
        orders[0].Status = 'Unplanned';
        orders[0].Replanned__c = true;
        orders[0].Load__c = null;
        update orders;
        Test.stopTest();

        List<aforza__Route_Location__c> routeLocationAcc = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, routeLocationAcc.size(), 'There should be route location left as only one order was removed.');

        List<aforza__Visit__c> visitAcc = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, visitAcc.size(), 'There should be Visit left as only one order was removed.');

        List<Task> tasksAcc = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc1.Id];
        Assert.areEqual(1, tasksAcc.size(), 'There should be Task left as only one order was removed.');

        List<aforza__Route__c> routeAcc = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, routeAcc.size(), 'There should be route left as only one order was removed.');

        List<Load__c> loadAcc = [SELECT Id FROM Load__c WHERE Id = :load.Id];
        Assert.areEqual(1, loadAcc.size(), 'There should be load left as only one order was removed.');
    }
}