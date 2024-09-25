@isTest
public with sharing class FetchQuoteDetailsForSalesOrderTest {
    public FetchQuoteDetailsForSalesOrderTest() {

    }

    @TestSetup static void makeData() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='123test562', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='test67381@gmail.com', IsActive = true);
        insert u;

        Account acc = new Account();
        acc.Name = 'test';
        acc.OwnerId = u.Id;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'testopp';
        opp.AccountId = acc.id;
        opp.stageName = 'Prospecting';
        opp.closeDate = Date.newInstance(2023,03,02);
        opp.Type = 'Existing Client';
        opp.Quote_Type__c = 'Replacement Parts';
        opp.Amount = 900.39;
        opp.OwnerId = u.Id;
        insert opp;

        
        Product2 prod = new Product2();
        prod.Name = 'test';
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        Update standardPricebook;

        //  Pricebook2 pb = new Pricebook2();
        //  pb.Name= 'test price book';
        //  pb.IsActive = true;
        //  pb.Description = 'test book';
        //  insert pb;

        

        
        //Id pricebookId = Test.getStandardPricebookId();
    


        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = standardPricebook.Id;
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 3444.43;
        pbe.IsActive=true;
        // pbe.UseStandardPrice = false;
        insert pbe;

        Customer_Asset__c objCA = new Customer_Asset__c();
        objCA.Name = 'test122';
        insert objCA;


        Quote quoteObj = new Quote();
        quoteObj.Name = 'testQuote123';
        quoteObj.OpportunityId = opp.Id;
        quoteObj.ShippingStreet = 'TEST 124';
        quoteObj.ShippingCity = 'testy';
        quoteObj.ShippingState = 'teststate';
        quoteObj.ShippingPostalCode = '99999';
        quoteObj.ShippingCountry = 'US';
        quoteObj.BillingStreet = 'TEST 122';
        quoteObj.BillingCity = 'testy2';
        quoteObj.BillingState = 'teststate2';
        quoteObj.BillingPostalCode = '44444';
        quoteObj.BillingCountry = 'US';
        quoteObj.pricebook2Id = standardPricebook.Id;
        quoteObj.Related_Conveyor__c = objCA.Id;
        quoteObj.OwnerId = u.Id;
        insert quoteObj;


        QuoteLineItem quoteLineObj = new QuoteLineItem ();
        quoteLineObj.Quantity = 2;
        quoteLineObj.Description = 'test';
        quoteLineObj.UnitPrice = 4444.33;
        quoteLineObj.Order_Created__c = false; 
        quoteLineObj.Product2Id = prod.Id;
        quoteLineObj.QuoteId = quoteObj.Id;
        quoteLineObj.PricebookEntryId = pbe.Id ;
        quoteLineObj.Related_Conveyor__c  = objCA.Id;
        quoteLineObj.Reference_Number__c = '313';
        quoteLineObj.End_Customer__c = acc.Id;
        quoteLineObj.Unit_of_Measure__c = 'EA';
        quoteLineObj.ServiceDate =  Date.newInstance(2023,03,02);
        insert quoteLineObj;


    }

    @isTest static void fetchQuoteDataPositive() {

        Quote quoteObj = [SELECT Id FROM Quote LIMIT 1];
        List<Quote> quoteList = new List<Quote>();

        Test.startTest();
            quoteList = FetchQuoteDetailsForSalesOrder.fetchQuoteData(quoteObj.Id);
        Test.stopTest();

        System.assertEquals(1,quoteList.size(),'list is not empty');
    }


    
    // @isTest static void fetchQuoteDataNegative() {

    //     Quote quoteObj = [SELECT Id FROM Quote LIMIT 1];
    //     List<Quote> quoteList = new List<Quote>();
    //     Boolean exceptionOccurred = false;

    //     Test.startTest();
    //         try{
    //         quoteList = FetchQuoteDetailsForSalesOrder.fetchQuoteData('80117000001IdQzAAK');
    //         }
    //         catch (DmlException unexpectedException)
    //         {
    //             exceptionOccurred = true;
    //         }

    //         Test.stopTest();
    //         System.assert(exceptionOccurred, 'An Exception was not thrown');

    // }


    @isTest public static void checkAccountNegative() {

        Boolean exceptionOccurred = false;
        
        Test.startTest();
        try {
        List<Account> accList = FetchQuoteDetailsForSalesOrder.getAccountData('xyz');
        }
        catch(Exception e){
            exceptionOccurred = true;
        }
        Test.stopTest();

        System.assert(exceptionOccurred, 'An Exception was not thrown');

        //System.debug('accList 1 '+accList);
        //System.assertEquals(0,accList.size(),'list is null');
    }

    @isTest public static void checkAccountPositive() {

        Test.startTest();
        List<Account> accList = FetchQuoteDetailsForSalesOrder.getAccountData('test');
        Test.stopTest();

        System.debug('accList 2 '+accList);
        System.assertEquals(1,accList.size(),'list is not null');
    }

    @isTest public static void checkPlaceOrder() {

        
        Account acc = [SELECT Id from Account LIMIT 1];
        System.debug('acc str id '+acc);

        Quote q = [SELECT id,Related_Conveyor__c,OpportunityId, OwnerId FROM Quote LIMIT 1];
        Product2 prodId = [SELECT Id from Product2 LIMIT 1];
        QuoteLineItem qtItem = [SELECT Id,QuoteId,Product2Id,
                                        Related_Conveyor__c,
                                        Reference_Number__c,
                                        End_Customer__c,
                                        Unit_of_Measure__c,
                                        ServiceDate from QuoteLineItem LIMIT 1];
        System.debug('prodId '+prodId+' qtItem '+qtItem);
        System.debug('Quote OwnerID: ' +q.OwnerId);
        User userId = [SELECT id FROM USER LIMIT 1];
        //String quoteId = String.valueOf(qtItem.QuoteId);

        String orderItemString = '{"SalesOrderDetails":{"Id":'+' "'+ qtItem.QuoteId  +'" '+',"OwnerId": '+' "'+ q.OwnerId +'" '+', "Name":"test blank quote","AccountId":'+' "' + acc.Id +'" ' +',"ShippingStreet":"707 7th Street Westyyyer","ShippingCity":"Huntington","ShippingState":"WV","ShippingPostalCode":"25704","ShippingCountry":"United States","BillingStreet":"707 7th Street West","BillingCity":"Huntington","BillingState":"WV","BillingPostalCode":"25704","BillingCountry":"United States","ShippingAddressU":"707 7th Street Westyyyer","CityU":"Huntington","StateU":"WV","PostalCodeU":"25704","CountryU":"United States","OrderDateU":"2023-03-18","CustomerPONumberU":"4442","InternalCommentsU":"hello","EndCustomerU":"","CustomerNotesU":"hey","TrialOrder":true,"RelatedConveyerId":'+' "'+ q.Related_Conveyor__c  +'" '+',"OpportunityId":'+' "'+ q.OpportunityId  +'" '+',"RequestDate":"2023-03-18"},'
        +'"SalesOrderLines":[{"QuoteId":'+' "'+ qtItem.QuoteId  +'" '+',"Id":'+' "'+ qtItem.Id  +'" '+',"Product2Id":'+' "'+ qtItem.Product2Id + '" '+',"LineNumber":"00000013",'
        +'"Quantity":2,"UnitPrice":8439,"Description":"Cleaning System","TotalPrice":16878,"Order_Created__c":false,"Product2":{"Name":"","Id":""},"Pname":"","PrintLine":true,"Clicked":"Unconfirm","CssClass":"delete-icn","CssClassPrintLine":"print-line-yes","Editable":false,"RelatedRootstockProduct":"","uom":'+' "'+ qtItem.Unit_of_Measure__c  +'" '+',"referenceNum":'+' "'+ qtItem.Reference_Number__c  +'" '+',"relatedConveyorId":'+' "'+ qtItem.Related_Conveyor__c  +'" '+',"endCustomerId":'+' "'+ qtItem.End_Customer__c  +'" '+',"ServiceDate":"2023-03-18"}]}';
        

        //String orderJSON = getOrderCreationData();     
        String orderJSON = orderItemString; 
        FetchQuoteDetailsForSalesOrder controller = new FetchQuoteDetailsForSalesOrder();        
        FetchQuoteDetailsForSalesOrder.OrderWrapper objOrderWrapper = new FetchQuoteDetailsForSalesOrder.OrderWrapper();
        FetchQuoteDetailsForSalesOrder.SODetails objCartItems = new FetchQuoteDetailsForSalesOrder.SODetails();
        

        
        objCartItems.Id = '';
        objCartItems.Name='';
        objCartItems.AccountId= String.valueOf(acc.Id);
        objCartItems.ShippingStreet='';
        objCartItems.ShippingCity='';
        objCartItems.ShippingState='';
        objCartItems.ShippingPostalCode='';
        objCartItems.ShippingCountry='';
        objCartItems.BillingStreet='';
        objCartItems.BillingCity='';
        objCartItems.BillingState='';
        objCartItems.BillingPostalCode='';
        objCartItems.BillingCountry='';
        objCartItems.ShippingAddressU='';
        objCartItems.CityU='';
        objCartItems.StateU='';
        objCartItems.PostalCodeU='';
        objCartItems.CountryU='';
        objCartItems.OrderDateU=null;
        objCartItems.CustomerPONumberU='';
        objCartItems.InternalCommentsU='';
        objCartItems.EndCustomerU='';
        objCartItems.CustomerNotesU='';
        objCartItems.trialOrder = null; 
        objCartItems.OwnerId = '';

        FetchQuoteDetailsForSalesOrder.SalesOrderLineItems objOrderLines = new FetchQuoteDetailsForSalesOrder.SalesOrderLineItems();


        objOrderLines.QuoteId= qtItem.QuoteId;
        objOrderLines.Id= qtItem.Id;
        objOrderLines.Product2Id= prodId.Id;
        objOrderLines.LineNumber='';
        objOrderLines.Quantity=null;
        objOrderLines.UnitPrice=null;
        objOrderLines.Description='';
        objOrderLines.TotalPrice=null; 
        objOrderLines.PrintLine = null;
        objOrderLines.Pname = '';
        objOrderLines.Clicked = '';
        
        FetchQuoteDetailsForSalesOrder.Products objProduct = new FetchQuoteDetailsForSalesOrder.Products();
        objProduct.Id = prodId.Id;
        objProduct.Name = 'test';

        Test.startTest();
            Map<Boolean,String> mapTest = FetchQuoteDetailsForSalesOrder.createSalesOrder(orderJson);
        Test.stopTest();

        System.Assert(mapTest.size()>0,'size of map should be gretaer than zero');
        System.assertEquals(false,mapTest.isEmpty(),'Map is not empty');
        System.assertEquals(false,String.isBlank(mapTest.get(true)),'Map is not empty');

    }



    @isTest public static String getOrderCreationData () {

        String orderItemString = '{"SalesOrderDetails":{"Id":"","Name":"test blank quote","AccountId":"","OwnerId":"","ShippingStreet":"707 7th Street Westyyyer","ShippingCity":"Huntington","ShippingState":"WV","ShippingPostalCode":"25704","ShippingCountry":"United States","BillingStreet":"707 7th Street West","BillingCity":"Huntington","BillingState":"WV","BillingPostalCode":"25704","BillingCountry":"United States","ShippingAddressU":"707 7th Street Westyyyer","CityU":"Huntington","StateU":"WV","PostalCodeU":"25704","CountryU":"United States","OrderDateU":"2023-03-18","CustomerPONumberU":"4442","InternalCommentsU":"hello","EndCustomerU":"","CustomerNotesU":"hey","TrialOrder":true},'
        +'"SalesOrderLines":[{"QuoteId":"","Id":"","Product2Id":"","LineNumber":"00000013",'
        +'"Quantity":2,"UnitPrice":8439,"Description":"Cleaning System","TotalPrice":16878,"Order_Created__c":false,"Product2":{"Name":"","Id":""},"Pname":"","PrintLine":true,"Clicked":"Unconfirm","CssClass":"delete-icn","CssClassPrintLine":"print-line-yes","Editable":false}]}';
        return orderItemString;
    }

    static Integer idCounter = 1;
    public static String getFakeId(Schema.SObjectType sot)
    {
       String result = String.valueOf(idCounter);
       idCounter ++;
       return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }
}