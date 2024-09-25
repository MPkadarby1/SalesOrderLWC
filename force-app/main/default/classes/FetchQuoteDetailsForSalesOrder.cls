public with sharing class FetchQuoteDetailsForSalesOrder {

    
    public FetchQuoteDetailsForSalesOrder() {
    }

    //testing
    @AuraEnabled
    public static List<rstk__soprod__c> fetchRstkProductMasterForOrderLineItem (List<String> idOrderLineList) {
        
        System.debug('Rootstock idOrderLineList '+idOrderLineList);
        List<rstk__soprod__c> rstkList = new List<rstk__soprod__c>();

        rstkList = [SELECT Id,Name,rstk__soprod_sf_product__c FROM rstk__soprod__c WHERE rstk__soprod_sf_product__c in: idOrderLineList];
        System.debug('Rootstock product list '+rstkList);
        return rstkList;
    }
    // 4.19 updated quote query to include the export and freight shipping charges from the Quote header
    @AuraEnabled
    public static List<Quote> fetchQuoteData (Id recordId) {
        List<Quote> quoteList = [SELECT id,Name,Account.Name,Account.OwnerId,AccountId,Export_Charges__c,Export_Charge_Amount_Multi_Currency__c, Freight_Charge__c, ShippingHandling, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,Related_Conveyor__c,Payment_Terms__c,OpportunityId,
                                        (select id,Product2.Name,LineNumber,Sales_Territory_Number__c,Product2Id,Quantity,UnitPrice,ServiceDate,Description__c,TotalPrice,Order_Created__c,Unit_of_Measure__c,Reference_Number__c,Related_Conveyor__c, Related_Conveyor_Populated__c, Related_Conveyor__r.Name,End_Customer__c,End_Customer__r.Name from QuoteLineItems WHERE Order_Created__c = FALSE) 
                                 FROM Quote where id =:recordId];

        return quoteList;
    }

    @AuraEnabled
    public static list<Account> getAccountData(String textkey) {
        textkey = '%' + textkey + '%';
        list<Account> accLst = [SELECT  Id, Name From Account WHERE Name LIKE :textkey];
        
        if(accLst.isEmpty()) {
            throw new AuraHandledException('No Record Found..');
        }
        return accLst; 
    }

    @AuraEnabled
    public static Map<Boolean,String> createSalesOrder (String orderJson) {
        System.debug('Order orderJson '+orderJson);
        OrderWrapper objWrapData = (OrderWrapper) System.JSON.deserialize(orderJson ,OrderWrapper.class );
        System.debug('Order Details '+objWrapData);

        Map<Boolean,String> finalOrderResultMap = new Map<Boolean,String>();

        //create Order  
        Order sohObj = new Order ();
        sohObj.AccountId = objWrapData.SalesOrderDetails.AccountId; //Account Name
        //customer address
        sohObj.BillingStreet  = String.isBlank(objWrapData.SalesOrderDetails.BillingStreet) ? '':objWrapData.SalesOrderDetails.BillingStreet;
        sohObj.BillingCity = String.isBlank(objWrapData.SalesOrderDetails.BillingCity) ? '':objWrapData.SalesOrderDetails.BillingCity;
        sohObj.BillingState = String.isBlank(objWrapData.SalesOrderDetails.BillingState) ? '':objWrapData.SalesOrderDetails.BillingState;
        sohObj.BillingPostalCode  = String.isBlank(objWrapData.SalesOrderDetails.BillingPostalCode) ? '':objWrapData.SalesOrderDetails.BillingPostalCode;
        sohObj.BillingCountry = String.isBlank(objWrapData.SalesOrderDetails.BillingCountry) ? '':objWrapData.SalesOrderDetails.BillingCountry;
        sohObj.Description = String.isBlank(objWrapData.SalesOrderDetails.InternalCommentsU) ? '':objWrapData.SalesOrderDetails.InternalCommentsU; //Internal Comments
        sohObj.QuoteId = String.isBlank(objWrapData.SalesOrderDetails.Id) ? '':objWrapData.SalesOrderDetails.Id;
        // 5.21.2024 adding in Payment Terms
        sohObj.Payment_Terms__c = String.isBlank(objWrapData.SalesOrderDetails.paymentTerms) ? '':objWrapData.SalesOrderDetails.paymentTerms;
        system.debug('Payment Terms captured are: ' + objWrapData.SalesOrderDetails.paymentTerms);
        //ShippingAddress
        sohObj.ShippingStreet  = String.isBlank(objWrapData.SalesOrderDetails.ShippingAddressU) ? '':objWrapData.SalesOrderDetails.ShippingAddressU;
        sohObj.ShippingCity = String.isBlank(objWrapData.SalesOrderDetails.CityU) ? '':objWrapData.SalesOrderDetails.CityU;
        sohObj.ShippingState = String.isBlank(objWrapData.SalesOrderDetails.StateU) ? '':objWrapData.SalesOrderDetails.StateU;
        sohObj.ShippingPostalCode  = String.isBlank(objWrapData.SalesOrderDetails.PostalCodeU) ? '':objWrapData.SalesOrderDetails.PostalCodeU;
        sohObj.ShippingCountry = String.isBlank(objWrapData.SalesOrderDetails.CountryU) ? '':objWrapData.SalesOrderDetails.CountryU;
        sohObj.Status = 'Booked';
        sohObj.EffectiveDate =  objWrapData.SalesOrderDetails.OrderDateU == null ? null: objWrapData.SalesOrderDetails.OrderDateU; //Order Start Date
        sohObj.PoNumber = String.isBlank(objWrapData.SalesOrderDetails.CustomerPONumberU) ? '':objWrapData.SalesOrderDetails.CustomerPONumberU; //Customer PO Number
        sohObj.Pricebook2Id =  '01s36000000KWDBAA4' ;
        sohObj.Trial__c = objWrapData.SalesOrderDetails.TrialOrder == null ? null: objWrapData.SalesOrderDetails.TrialOrder;
        System.debug('The trial is set to: ' +objWrapData.SalesOrderDetails.trialOrder);
        //sohObj.Customer_Notes__c = String.isBlank(objWrapData.SalesOrderDetails.CustomerNotesU) ? '':objWrapData.SalesOrderDetails.CustomerNotesU;
        sohObj.Customer_Notes_RichText__c = String.isBlank(objWrapData.SalesOrderDetails.CustomerNotesU) ? '':objWrapData.SalesOrderDetails.CustomerNotesU;
        System.debug('Related_Conveyor__c '+objWrapData.SalesOrderDetails.RelatedConveyerId);
        System.debug('EndCustomerU order '+objWrapData.SalesOrderDetails.EndCustomerU);
        sohObj.End_Customer__c = String.isBlank(objWrapData.SalesOrderDetails.EndCustomerU) ? objWrapData.SalesOrderDetails.AccountId:objWrapData.SalesOrderDetails.EndCustomerU;
        sohObj.OwnerId = String.isBlank(objWrapData.SalesOrderDetails.OwnerId) ? '':objWrapData.SalesOrderDetails.OwnerId;
        //testing 1234 
        System.debug('owner id '+objWrapData.SalesOrderDetails.OwnerId);
		// sohObj.Related_Conveyor__c = String.isBlank(objWrapData.SalesOrderDetails.RelatedConveyerId) || objWrapData.SalesOrderDetails.RelatedConveyerId == null ? '':objWrapData.SalesOrderDetails.RelatedConveyerId;
		sohObj.Related_Conveyor__c = String.isBlank(objWrapData.SalesOrderDetails.RelatedConveyerId) || objWrapData.SalesOrderDetails.RelatedConveyerId == null ? null:objWrapData.SalesOrderDetails.RelatedConveyerId;
        sohObj.OpportunityId = String.isBlank(objWrapData.SalesOrderDetails.OpportunityId) ? '':objWrapData.SalesOrderDetails.OpportunityId;
        sohObj.Requested_Ship_Date__c = objWrapData.SalesOrderDetails.RequestDate == null ? null: objWrapData.SalesOrderDetails.RequestDate; //Requested Ship Date
        // 4.19.2024 Updating to map the export and shipping charges to the Order Header
        sohObj.Export_Charge__c = String.isBlank(objWrapData.SalesOrderDetails.exportCharge) ? '': objWrapData.SalesOrderDetails.exportCharge;
        System.debug('Export Charge: ' +objWrapData.SalesOrderDetails.exportCharge);
        sohObj.Export_Charge_Amount_Multi_Currency__c = objWrapData.SalesOrderDetails.exportChargeTotal == null ? null: objWrapData.SalesOrderDetails.exportChargeTotal;
        System.debug('Export Charge Total: $' + objWrapData.SalesOrderDetails.exportChargeTotal);
        sohObj.Freight_Charge__c = String.isBlank(objWrapData.SalesOrderDetails.freightCharge) ? '': objWrapData.SalesOrderDetails.freightCharge;
        System.debug('Freight Charge: ' +objWrapData.SalesOrderDetails.freightCharge);
        sohObj.Freight_Charges_Amount__c = objWrapData.SalesOrderDetails.freightChargeTotal == null ? null: objWrapData.SalesOrderDetails.freightChargeTotal;
        System.debug('Freight Charge Total: $' +objWrapData.SalesOrderDetails.freightChargeTotal);

      
        //testing 1234 
        try {
            insert sohObj;
            //Database.insert(sohObj,false);
            } catch(DMLException e) {
                System.debug('Error message now '+e.getMessage());
            throw new AuraHandledException('Unable to Perform the DML Operation on Order : ' +e.getMessage());
            //return false;
        }
        
        System.debug('Object now '+sohObj);
        System.debug('Id now '+sohObj.Id);
        Order orderName = [SELECT id,OrderNumber FROM Order where id =: sohObj.Id LIMIT 1];    
        String tempStr = 'Sales Order '+orderName.OrderNumber+' was created Successfully!'; 
        finalOrderResultMap.put(true,tempStr);

        List<OrderItem> orderItemList = new List<OrderItem>();
        List<PricebookEntry> priceBookItemList = new List<PricebookEntry>();
        

        for (SalesOrderLineItems i : objWrapData.SalesOrderLines) {
            
            System.debug('i Th item standardPriceObj '+i);


            // Insert PricebookEntry
            PricebookEntry standardPriceObj = new PricebookEntry();
            if(Test.isRunningTest()){
            standardPriceObj = [SELECT id,name,Pricebook2Id,Product2Id,UnitPrice,IsActive FROM PricebookEntry  where Product2Id =:i.Product2Id LIMIT 1];
            System.debug('standardPriceObj '+standardPriceObj);
            }
            else
            {
                standardPriceObj = [SELECT id,name,Pricebook2Id,Product2Id,UnitPrice,IsActive FROM PricebookEntry  where Product2Id =:i.Product2Id AND Pricebook2Id = '01s36000000KWDBAA4' LIMIT 1];
            }
            // standardPriceObj.Pricebook2Id = '01s36000000KWDBAA4';
            // standardPriceObj.Product2Id = i.Product2Id;
            // standardPriceObj.UnitPrice = 1;
            // standardPriceObj.IsActive = true;
            // standardPriceObj.UseStandardPrice = false;
             priceBookItemList.add(standardPriceObj);

        }

        //Boolean priceBookEntryFlag = insertPriceBookEntry(priceBookItemList);
        // try {
        //     insert priceBookItemList;
        //     } catch(DMLException e) {
        //     throw new DMLException('Unable to Perform the DML Operation on PricebookEntry : ' +e.getMessage());
        // }


        for (Integer j = 0; j < objWrapData.SalesOrderLines.size(); j++ ) {

            System.debug('objWrapData.SalesOrderLines '+objWrapData.SalesOrderLines[j]);
            //create Order item 
            OrderItem soiObj = new OrderItem();
            soiObj.OrderId = sohObj.id;
            soiObj.Quantity = objWrapData.SalesOrderLines[j].Quantity;
            soiObj.UnitPrice = objWrapData.SalesOrderLines[j].UnitPrice;
            soiObj.Product2id = objWrapData.SalesOrderLines[j].Product2Id;
            soiObj.PricebookEntryId=priceBookItemList[j].id;
            soiObj.Print_Line__c = objWrapData.SalesOrderLines[j].PrintLine;
            soiObj.Related_Rootstock_Product__c = String.isBlank(objWrapData.SalesOrderLines[j].RelatedRootstockProduct) ? null:objWrapData.SalesOrderLines[j].RelatedRootstockProduct;
            soiObj.Description__c = String.isBlank(objWrapData.SalesOrderLines[j].Description) ? '':objWrapData.SalesOrderLines[j].Description;
            System.debug('Description test 123 '+objWrapData.SalesOrderLines[j].Description);
            //testing
            soiObj.Related_Quote_Line_Item__c =  objWrapData.SalesOrderLines[j].Id;
            //testing
            soiObj.End_Customer__c = String.isBlank(objWrapData.SalesOrderLines[j].endCustomerId) ? objWrapData.SalesOrderDetails.AccountId: objWrapData.SalesOrderLines[j].endCustomerId;
            soiObj.Unit_of_Measure__c = String.isBlank(objWrapData.SalesOrderLines[j].uom) ? '':objWrapData.SalesOrderLines[j].uom;
            //4.22.2024 adding the mapping of the sales territory number at the order line level
            soiObj.Sales_Territory_Number__c = String.isBlank(objWrapData.SalesOrderLines[j].salesTerritoryNumber) ? '': objWrapData.SalesOrderLines[j].salesTerritoryNumber;
            System.debug('Sales Territory Number on the Line: ' +objWrapData.SalesOrderLines[j].salesTerritoryNumber);
            soiObj.Reference_Number__c = String.isBlank(objWrapData.SalesOrderLines[j].referenceNum) ? '':objWrapData.SalesOrderLines[j].referenceNum;
           System.debug('Related_Conveyor__c '+objWrapData.SalesOrderLines[j].relatedConveyorId);
           soiObj.Related_Conveyor__c = objWrapData.SalesOrderLines[j].relatedConveyorId == null ? null:objWrapData.SalesOrderLines[j].relatedConveyorId;
           //5.10.2024 adding the Related Conveyor Populated mapping at the line level
           soiObj.Related_Conveyor_Populated__c = objWrapData.SalesOrderLines[j].relatedConveyorID == null ? false:true;
           System.debug('End customer quote line '+objWrapData.SalesOrderLines[j].endCustomerId);
           soiObj.Created_from_LWC__c = true;
            if(objWrapData.SalesOrderLines[j].ServiceDate ==  null && 
            objWrapData.SalesOrderDetails.RequestDate != null) {
                soiObj.Material_Due_Date__c = objWrapData.SalesOrderDetails.RequestDate;
            }  
            else if(objWrapData.SalesOrderLines[j].ServiceDate !=  null){
                soiObj.Material_Due_Date__c = objWrapData.SalesOrderLines[j].ServiceDate;
            }
            //Requested date
           //soiObj.End_customer_new__c = String.isBlank(objWrapData.SalesOrderLines[j].endCustomerId) ? '':objWrapData.SalesOrderLines[j].endCustomerId;
           //testing 1234
           

            orderItemList.add(soiObj);
        }

        Boolean orderItemListInsertFlag = insertEntry(orderItemList);
        if(orderItemListInsertFlag != true) {

            finalOrderResultMap.clear();
            finalOrderResultMap.put(false,'Order item not inserted');

            return finalOrderResultMap;
        }

        List<QuoteLineItem> qtLineItemsUpdateList = new List<QuoteLineItem>();

        for (Integer r = 0; r < objWrapData.SalesOrderLines.size(); r++ ) {
            
            QuoteLineItem obj = new QuoteLineItem();
            obj.Id = objWrapData.SalesOrderLines[r].Id;
            obj.Order_Created__c = true;
            qtLineItemsUpdateList.add(obj);
        }

        try {
            Database.update(qtLineItemsUpdateList,false);
            
            //testing
            // System.debug('orderitemList '+orderItemList);

            // //Map<Id,Opportunity_Asset__c> oppAssetUpdateList = new Map<Id,Opportunity_Asset__c>();
            // List<Opportunity_Asset__c> oppAssetUpdateList1 =new List<Opportunity_Asset__c>();
            // List<Opportunity_Asset__c> oppAssetUpdateList2 =new List<Opportunity_Asset__c>();
        
            
            // for(OrderItem ordItemObj : orderItemList) {

            //     System.debug('ordItemObj '+ordItemObj);
            //     System.debug('Entered loop ');
            //     System.debug('quote line item '+ordItemObj.Related_Quote_Line_Item__c);

            //     Opportunity_Asset__c [] opAssetObj = [SELECT Id,Name,Related_Quote__r.Name,Related_Quote__c,Related_Quote_Line_Item__c 
            //                                               FROM Opportunity_Asset__c 
            //                                               WHERE Related_Quote_Line_Item__c =: ordItemObj.Related_Quote_Line_Item__c ];
        
                                                        
            //    System.debug('opAssetObj '+opAssetObj);
                                                          

                
            //     if(opAssetObj.size() > 0) {

            //         for(Opportunity_Asset__c op : opAssetObj) {
            //             Opportunity_Asset__c oaObj = new Opportunity_Asset__c();                                          

            //             oaObj.Id = op.Id;
            //             oaObj.Related_Booked_Order__c = sohObj.Id;
            //             oaObj.Related_Booked_Order_Line__c = ordItemObj.Id;
            //             oppAssetUpdateList1.add(oaObj);
            //             System.debug('Entered 1');
            //         }

            //     }
               

            // }
            // System.debug('oppAssetUpdateList 1 '+oppAssetUpdateList1);



            //process 2

            // List<Opportunity_Asset__c> opAssetObj1 = [SELECT Id,Name,Related_Quote__r.Name,Related_Quote__c,Related_Quote_Line_Item__c 
            //                                           FROM Opportunity_Asset__c 
            //                                           WHERE  Related_Quote__c =: sohObj.QuoteId ];

            //      System.debug('opAssetObj1 '+opAssetObj1);
            //      System.debug('opAssetObj1 size '+opAssetObj1.size());


            //     if(opAssetObj1.size() > 0) {

            //         for(Integer i = 0; i < opAssetObj1.size() ; i++) {
            //             Opportunity_Asset__c oaObjQ = new Opportunity_Asset__c();                                          
            //             oaObjQ.Id = opAssetObj1[i].Id;
            //             oaObjQ.Related_Booked_Order__c = sohObj.Id;
            //             oppAssetUpdateList2.add(oaObjQ);

            //         }
                                
            
            //     }  
            //     System.debug('Entered 2');

            //process 2


            // System.debug('oppAssetUpdateList 2 '+oppAssetUpdateList2);

            //List<Opportunity_Asset__c> oppAssetFinalList = oppAssetUpdateList.values();

                // if(oppAssetUpdateList1.size() > 0) {
                //     System.debug('entered if');
                //     System.debug('oppAssetFinalList final 1 '+oppAssetUpdateList1);
                //     update oppAssetUpdateList1;
                // }
                // else {
                //     System.debug('entered else 1');
                // }

                // if(oppAssetUpdateList2.size() > 0) {
                //     System.debug('entered if');
                //     System.debug('oppAssetFinalList final 2 '+oppAssetUpdateList2);
                //     update oppAssetUpdateList2;
                // }
                // else {
                //     System.debug('entered else 2');
                // }


            //testing
            
            return finalOrderResultMap;
        }
        catch(Exception e) {
            throw new AuraHandledException('Unable to Perform the DML Operation on Qoute line items to update checkbox  : ' +e.getMessage());
        }


        //testing


        // List<Opportunity_Asset__c> opAssetList = [SELECT Id,Name,Related_Quote__r.Name,Related_Quote__c 
        //                                           FROM Opportunity_Asset__c 
        //                                           WHERE Related_Quote__c =: sohObj.QuoteId];
        
        
        // if(oppAseerList.size() > 0) {
            
        // }





        //testing
    }


    public static Boolean insertEntry(List<SObject> dynamicItemList) {
       
        Map<String,String> resultMap = new Map<String,String>();
        Database.SaveResult[] saveResultList = Database.insert(dynamicItemList, false);

        for (Database.SaveResult sr : saveResultList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                 resultMap.put('Success',String.valueOf(sr.isSuccess()));
                 resultMap.put('SuccessId',String.valueOf(sr.getId()));
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    resultMap.put('Success','False');
                    resultMap.put('ErrorStatus',String.valueOf(err.getStatusCode()));
                    resultMap.put('ErrorMessage',String.valueOf( err.getMessage()));

        
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                    //return false;
                    throw new AuraHandledException(err.getMessage());

                }
            }
        }
        return true;
    }

    public class OrderWrapper {

        @AuraEnabled
        public SODetails SalesOrderDetails;

        @AuraEnabled
        public List<SalesOrderLineItems> SalesOrderLines;

        public OrderWrapper() {
            SalesOrderDetails = new SODetails();
            SalesOrderLines = new List<SalesOrderLineItems>();
        }

    }

    public class SODetails {

        @AuraEnabled 
        public String Id;
        @AuraEnabled 
        public String Name;
        @AuraEnabled 
        public String AccountId;
        @AuraEnabled 
        public String ShippingStreet;
        @AuraEnabled 
        public String ShippingCity;
        @AuraEnabled 
        public String ShippingState;
        @AuraEnabled 
        public String ShippingPostalCode;
        @AuraEnabled 
        public String ShippingCountry;
        @AuraEnabled 
        public String BillingStreet;
        @AuraEnabled 
        public String BillingCity;
        @AuraEnabled 
        public String BillingState;
        @AuraEnabled 
        public String BillingPostalCode;
        @AuraEnabled 
        public String BillingCountry;
        @AuraEnabled 
        public String ShippingAddressU;

        @AuraEnabled 
        public String CityU;
        @AuraEnabled 
        public String StateU; 
        @AuraEnabled 
        public String PostalCodeU; 
        @AuraEnabled 
        public String CountryU; 
        @AuraEnabled 
        public Date OrderDateU; 
        @AuraEnabled 
        public String CustomerPONumberU; 
        @AuraEnabled 
        public String InternalCommentsU; 
        @AuraEnabled 
        public String EndCustomerU; 
        @AuraEnabled 
        public String CustomerNotesU;
        @AuraEnabled
        public Boolean trialOrder;
        @AuraEnabled
        public String OwnerId;
        @AuraEnabled
        public String RelatedConveyerId;
        @AuraEnabled
        public String OpportunityId;
        @AuraEnabled
        public Date RequestDate;
        // 4.19.2024 Adding to support the mapping of the export and freight charges
        @AuraEnabled
        public String exportCharge;
        @AuraEnabled
        public Decimal exportChargeTotal;
        @AuraEnabled
        public Decimal freightChargeTotal;
        @AuraEnabled
        public String freightCharge;
        // 5.21.2024 Adding to support mapping of the payment terms
        @AuraEnabled
        public string paymentTerms;

        public SODetails(){
            Id = '';
            Name='';
            AccountId='';
            ShippingStreet='';
            ShippingCity='';
            ShippingState='';
            ShippingPostalCode='';
            ShippingCountry='';
            BillingStreet='';
            BillingCity='';
            BillingState='';
            BillingPostalCode='';
            BillingCountry='';
            ShippingAddressU='';
            CityU='';
            StateU='';
            PostalCodeU='';
            CountryU='';
            OrderDateU=null;
            CustomerPONumberU='';
            InternalCommentsU='';
            EndCustomerU='';
            CustomerNotesU='';
            trialOrder = false; 
            OwnerId='';
            RelatedConveyerId='';
            OpportunityId = '';
            RequestDate = null;
            // initializing the export and freight charge variables
            exportCharge ='';
            exportChargeTotal = null;
            freightChargeTotal = null;
            freightCharge = '';
            paymentTerms = '';

        }
    }

    public class SalesOrderLineItems {

        @AuraEnabled 
        public String QuoteId;
        @AuraEnabled 
        public String Id;
        @AuraEnabled 
        public String Product2Id;
        @AuraEnabled 
        public String LineNumber;
        @AuraEnabled 
        public Integer Quantity; 
        @AuraEnabled 
        public Decimal UnitPrice;
        // public Integer UnitPrice;
        @AuraEnabled 
        public String Description;
        @AuraEnabled 
        public Decimal TotalPrice;
        // public Integer TotalPrice;
        @AuraEnabled
        public Products Product2;
        @AuraEnabled
        public String Pname;
        @AuraEnabled
        public Boolean PrintLine;
        @AuraEnabled
        public String Clicked;
        @AuraEnabled
        public String RelatedRootstockProduct;
        @AuraEnabled
        public String uom;
        @AuraEnabled
        public String referenceNum;
        @AuraEnabled
        public String relatedConveyorId;  
        @AuraEnabled
        public String endCustomerId;
        @AuraEnabled
        public Date ServiceDate;
        @AuraEnabled
        public String salesTerritoryNumber;
        

        public SalesOrderLineItems() {

            QuoteId='';
            Id='';
            Product2Id='';
            LineNumber='';
            Quantity=null;
            UnitPrice=null;
            Description='';
            TotalPrice=null; 
            PrintLine = null;
            Product2 = new Products();
            Pname = '';
            Clicked = '';
            RelatedRootstockProduct='';
            uom='';
            salesTerritoryNumber='';
            referenceNum='';
            relatedConveyorId = '';
            endCustomerId = '';
            ServiceDate = null;
        }
    }

    public class Products{
        @AuraEnabled 
        public String Id;
        @AuraEnabled 
        public String Name;

        public Products() {
            Id = '';
            Name= '';
        }
    }

}