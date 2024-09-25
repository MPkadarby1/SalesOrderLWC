import { LightningElement,api,wire,track } from 'lwc';
import fetchQuoteData from '@salesforce/apex/FetchQuoteDetailsForSalesOrder.fetchQuoteData';
import createSalesOrder from '@salesforce/apex/FetchQuoteDetailsForSalesOrder.createSalesOrder';
import getAccountSearch from '@salesforce/apex/FetchQuoteDetailsForSalesOrder.getAccountData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SalesOrderForQuoteLineItem extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track showHome;
    @track isReadOnly;
    @track quoteData;
    @track quoteObj = {};
    @track accName;
    @track quoteLineItem = [];
    @track showDatatable;
    @track showCustomerNotesFlow;
    @track customerNotes;
    @track fetchItemList;
    @track confirmedQuoteList = [];
    @track error;
    @track trialButtonFlag;
    @track searchPack = {searchTerm : '',searchId: ''};
    @track searchKey;
    @track accounts;
    @track isLoading;
    boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    inputClass = '';
    inputError = '';
    @track currentDate;
    @track btSalesOrder;
    @track accountIdForFlow;

    //testing 1234 
    @track initialRelatedConveyer;
    //testing 1234

    //testing
    get inputVariables() {
        return [
            {
                name: 'accountId',
                type: 'String',
                value: this.accountIdForFlow
            }
        ];
    }

    handleFlowModalClose(event) {
        console.log("Reached parent from child ");
        console.log("DATA +++++++ "+JSON.stringify(event.detail));
        if(event.detail.modalStatus === false) {
            this.showCustomerNotesFlow =false;
        }
        if(event.detail.customerNotes){
            console.log("working1");
        let valueStr = (event.detail.customerNotes).toString(); 
        this.customerNotes = valueStr;
        console.log("customer notes "+this.customerNotes);
        }

    }

    

    connectedCallback() {
        this.isReadOnly = true;
        this.showCustomerNotesFlow = false;
        this.trialButtonFlag = false;
        this.isLoading = true;
        this.showDatatable = false;
        console.log("Record Id "+this.recordId);
        console.log("Trial flag is set to " +this.trialButtonFlag);
        this.fetchDataInitial();
        this.calculateDate();

    }

    calculateDate() {
        let d = new Date();
        let newD = new Date(d.getTime() + d.getTimezoneOffset()*60000);
        this.currentDate = newD.toISOString().slice(0,10);
        console.log('Date '+JSON.stringify(newD));
        console.log("DATE ++++++ "+JSON.stringify(this.currentDate));   

    }

    handleInlineEdit(event) {
        console.log("Refresh in parent "+JSON.stringify(event.detail));
        this.isLoading = true;
        this.fetchDataInitial();
    }

    //testing
    toggleCreateOrderButton(event) {
        console.log("hide button in parent "+JSON.stringify(event.detail));
        if(event.detail === true) {
            this.btSalesOrder = true;
        }
        else if(event.detail === false) {
            this.btSalesOrder = false;
        }
    }

    fetchDataInitial() {
        fetchQuoteData({recordId : this.recordId})
        .then((data) => {
            console.log("DATA SEARCH RESULTS "+JSON.stringify(data));
            this.quoteObj = data[0];
            this.accName = this.quoteObj["Account"].Name;
            this.accountIdForFlow = this.quoteObj["Account"].Id;
            console.log("Account Name "+JSON.stringify(this.accName)); 
            console.log("Payment Terms are " +JSON.stringify(this.quoteObj.Payment_Terms__c))
            console.log("DATA SEARCH RESULTS "+JSON.stringify(  this.quoteObj));

            let temp = data;
            this.quoteData = temp; 
            this.quoteLineItem = this.quoteData[0].QuoteLineItems;


            //testing 1234   
            if(this.quoteLineItem) {

            
            this.quoteLineItem = this.quoteLineItem.map(obj=>({...obj,relatedConveyorName:"",endCustomerName:"",Description:"",relatedConveyorId:null,endCustomerId:null}))
            this.quoteLineItem.forEach(res =>{
                
                if(res.Related_Conveyor__c) {
                res.relatedConveyorName = res.Related_Conveyor__r["Name"]; 
                res.relatedConveyorId = res.Related_Conveyor__c;    
            } //for quote lien item's related conveyer
                
                if(res.End_Customer__c) {
                res.endCustomerName = res.End_Customer__r["Name"]; //for quote lien item's end customer
                res.endCustomerId = res.End_Customer__c;    
            }

            if(res.Description__c) {
                res.Description = res.Description__c;
            }

        });

            if(this.quoteData[0].Related_Conveyor__c) {
                this.initialRelatedConveyer = this.quoteData[0].Related_Conveyor__c;
            }
        }
            //testing 1234

            if(this.quoteLineItem) {
                this.showHome = true;
                this.showDatatable = true;
            }
            else 
            {
                this.showHome = false;
                this.showDatatable = false;
            }
            console.log("DATA SEARCH RESULTS "+JSON.stringify(this.quoteData));
            this.isLoading = false;

        }).catch((error)=>{
            console.log("ERROR "+JSON.stringify(error));

        })
    }

    @api
    get trialFlag() {
        return this.trialButtonFlag;
    }

    set trialFlag(value) {
       this.trialButtonFlag = value;
    }

    handleTrial(event) {
        console.log("trial result "+JSON.stringify(event.target.title));
        this.trialButtonFlag = !this.trialButtonFlag;
        console.log("The trial is set to: " +this.trialButtonFlag)
    }

    handleAccountSearchChange(event){
        this.searchKey = event.target.value;
        //if(!this.searchKey) {
            //this.accounts = this.accountDefault;
        //}
        //else {
            if(this.searchKey) {
                this.SearchAccountHandler();
            }
        //}
    }
    
    handleAccountSearchClick() {
        console.log("Clicked 1");
        //testing
        //this.template.querySelector("[data-name='CustomerNotesU']").value = '';
        //testing
        this.searchKey = '';
        this.accounts = [];
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onSelect(event) {
        console.log("Clicked 2");
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-close';
        let selectedName = event.currentTarget.dataset.name;
        this.searchPack.searchTerm = selectedName;
        this.searchPack.searchId = event.currentTarget.dataset.id;
        console.log("Selected Name "+JSON.stringify(selectedName));
        console.log("Selected Id "+JSON.stringify(event.currentTarget.dataset.id));
    }

    SearchAccountHandler(){
        //call Apex method.
        getAccountSearch({textkey: this.searchKey})
        .then(result => {
                this.accounts = result;
                // if(this.isLoadedAccount) {
                //     this.accountDefault = this.accounts;
                //     this.isLoadedAccount = false;
                // }
                this.inputClass = 'slds-has-focus';
                this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';

                console.log("Accounts++++ "+JSON.stringify(this.accounts));
        })
        .catch( error=>{
            console.log("Accounts error "+JSON.stringify(error));
            this.accounts = null;
        });

    }

    quoteItemListFromChildHandler(event) {
        this.fetchItemList = "No";
        console.log("Reached");
        console.log("Quote list from child "+JSON.stringify(event.detail));
        this.confirmedQuoteList = event.detail;
        console.log("Quote list from child "+JSON.stringify(this.confirmedQuoteList));
        if(this.confirmedQuoteList.length != 0) {
            this.placeSalesOrder();
        }
    }

        handleSubmit(event) {
        console.log('clicked');

        this.fetchItemList = 'Yes';

        
    }

    showCustomerNotes() {
        console.log("Initial flag "+JSON.stringify(this.showCustomerNotesFlow));
        this.showCustomerNotesFlow = !this.showCustomerNotesFlow;
        console.log("Final flag "+JSON.stringify(this.showCustomerNotesFlow));
    }

    handleStatusChange(event) {
        console.log("Entered flow");
        console.log("status "+JSON.stringify(event.detail.status));
        if(event.detail.status === 'FINISHED'){
            this.showCustomerNotes();
            const outputVariables = event.detail.outputVariables;
            console.log('output variables '+JSON.stringify(outputVariables));
            for(let i = 0; i < outputVariables.length; i++) {
                const outputVar = outputVariables[i];
                if(outputVar.name == 'customerNotesOutput'){
                    console.log("working");
                    console.log("OUTPUT "+outputVar.value);
                    console.log("OUTPUT "+JSON.stringify(outputVar.value));
                    console.log("check");
                  
                    if(outputVar.value){
                        console.log("entered str");
                        let str = (outputVar.value).toString();
                        console.log("Str "+str);
                        let my_new_string = str.replaceAll("p","li");
                        console.log("my_new_string "+my_new_string);
                        this.customerNotes = my_new_string;
                    
                    }
                }
            }
        }
    }

    //testing
    allDeleted(event) {
        console.log("hide home");
        console.log("hide home event "+JSON.stringify(event.detail));
        if(event.detail === false) {
            this.showHome = false;
        }
    }

    placeSalesOrder() {
        this.isLoading = true;
        
        var orderWrapData = { SalesOrderDetails: "", SalesOrderLines: "" };
            console.log("Quote Obj 1 "+JSON.stringify(this.quoteObj));
            console.log("Quote Obj 1 "+JSON.stringify(this.confirmedQuoteList));

            
            this.confirmedQuoteList = this.confirmedQuoteList.map(obj=>({...obj,Description:"",uom:"",referenceNum:"", salesTerritoryNumber:""}))
            let kItem =0;
            while(kItem<this.confirmedQuoteList.length) {
               this.confirmedQuoteList[kItem].Description = 
                this.confirmedQuoteList[kItem].Description__c;
                
                this.confirmedQuoteList[kItem].uom = 
                this.confirmedQuoteList[kItem].Unit_of_Measure__c;
                
                
                this.confirmedQuoteList[kItem].referenceNum = 
                this.confirmedQuoteList[kItem].Reference_Number__c;
               

                this.confirmedQuoteList[kItem].salesTerritoryNumber = this.confirmedQuoteList[kItem].Sales_Territory_Number__c;
                kItem++;
            } 
            

            let obj = { Id: this.quoteObj.Id,
                        Name : this.quoteObj.Name,
                        AccountId : this.quoteObj.AccountId,
                        ShippingStreet : this.quoteObj.ShippingStreet,
                        ShippingCity : this.quoteObj.ShippingCity,
                        ShippingState : this.quoteObj.ShippingState,
                        ShippingPostalCode : this.quoteObj.ShippingPostalCode,
                        ShippingCountry : this.quoteObj.ShippingCountry,
                        BillingStreet : this.quoteObj.BillingStreet,
                        BillingCity : this.quoteObj.BillingCity,
                        BillingState : this.quoteObj.BillingState,
                        BillingPostalCode : this.quoteObj.BillingPostalCode,
                        BillingCountry   : this.quoteObj.BillingCountry,
                        ShippingAddressU : this.template.querySelector("[data-name='ShippingAddress']").value,
                        CityU : this.template.querySelector("[data-name='CityU']").value,
                        StateU : this.template.querySelector("[data-name='StateU']").value,
                        PostalCodeU : this.template.querySelector("[data-name='PostalCodeU']").value,                        
                        CountryU : this.template.querySelector("[data-name='CountryU']").value,
                        OrderDateU : this.template.querySelector("[data-name='OrderDateU']").value,
                        CustomerPONumberU : this.template.querySelector("[data-name='CustomerPONumberU']").value,
                        InternalCommentsU : this.template.querySelector("[data-name='InternalCommentsU']").value,
                        EndCustomerU :   this.searchPack.searchId,
                        CustomerNotesU : this.template.querySelector("[data-name='CustomerNotesU']").value,
                        //TrialOrder : this.trialButtonFlag === 'true' ? false : true,
                       //TrialOrder : this.trialButtonFlag ? false : true,
                       TrialOrder: this.trialButtonFlag,
                        OwnerId : this.quoteObj["Account"].OwnerId,
                        RelatedConveyerId :  this.initialRelatedConveyer,
                        OpportunityId : this.quoteObj.OpportunityId,
                        RequestDate : this.template.querySelector("[data-name='RequestDate']").value == "" ? null:this.template.querySelector("[data-name='RequestDate']").value,
                        //4.19.2024 adding in the mapping for the export and freight charges
                        exportCharge : this.quoteObj.Export_Charges__c,
                        exportChargeTotal : this.quoteObj.Export_Charge_Amount_Multi_Currency__c,
                        freightChargeTotal : this.quoteObj.ShippingHandling,
                        freightCharge : this.quoteObj.Freight_Charge__c,
                        paymentTerms: this.quoteObj.Payment_Terms__c

                    }


            orderWrapData.SalesOrderDetails = obj;

            //to be sent for creation of order having confirmed clicked
            let confirmedQuoteFinal = this.confirmedQuoteList;
            confirmedQuoteFinal = confirmedQuoteFinal.filter(function(item) {
                return item.Clicked  === 'Unconfirm';
            })

            //testing
            //if(!confirmedQuoteFinal.length)
            if(this.confirmedQuoteList.length !== confirmedQuoteFinal.length ) {
                this.error = 'Please confirm all the Sales Order Lines before proceeding!';
                this.showToast("error",this.error);
                this.isLoading = false;
            }
            else {

                orderWrapData.SalesOrderLines =  confirmedQuoteFinal;

                console.log("Quote Obj 2 "+JSON.stringify(orderWrapData.SalesOrderDetails ));
                console.log("Quote Obj 2 "+JSON.stringify(orderWrapData.SalesOrderLines ));
                console.log("Quote Obj 3 "+JSON.stringify(orderWrapData ));

                var validityStatus = this.checkValidity();
    
                if(validityStatus === true && orderWrapData != null) {
                        createSalesOrder({
                            orderJson: JSON.stringify(orderWrapData)
                        })
                        .then(result =>{
                            console.log("Boolean result 1 "+JSON.stringify(result));
                            let arrResult = Object.keys(result);
                            console.log("Arr result "+JSON.stringify(arrResult));
                            
                            if(arrResult[0]=== "true"){
                                console.log("Boolean result 2 "+JSON.stringify(result));
                                this.showToast("success",result["true"]);
                               
                                this.fetchDataInitial();
                                //this.isLoading = false;
                            }
                        })
                        .catch(error =>{
                            console.log("Boolean result 3 "+JSON.stringify(error));
                            this.isLoading = false;
                            this.error = error.body.message;
                            this.showToast("error",this.error);
                        });
                }
                else {
                    console.log("Boolean result 4");
                    this.isLoading = false;
                    //this.scrollIntoView();
                    this.showToast("error",this.error);
                }
            }

    }

    scrollIntoView(){
        console.log("input error "+JSON.stringify(this.inputError));
        let errorinput = this.template.querySelector(`lightning-input[label="${this.inputError}"]`); //phone,email
        console.log("error input "+JSON.stringify(errorinput.value));
        errorinput.scrollIntoView({
            behavior: "smooth", 
            block: "center"
        });  
    }

    showToast(variantValue,msg) {
        const event = new ShowToastEvent({
            title: variantValue,
            variant:variantValue,
            message:msg
        });
        this.dispatchEvent(event);
    }

    checkValidity() {
         let errorInput = '';
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            if(inputCmp.reportValidity() === false) {
                console.log("Report Validity label "+JSON.stringify(inputCmp.label));
                this.error = 'This Sales Order Failed due to incorrect or missing field named ' +inputCmp.label;
                //errorInput = inputCmp.label;
                this.inputError = inputCmp.label;
            }
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            return true;
            //alert('All form entries look valid. Ready to submit!');
        } else {
            //this.scrollIntoView(errorInput);
            return false;
            //alert('Please update the invalid form entries and try again.');
        }
    }

    handleRelatedConveyer(event) {
        console.log("related conveyer selected "+event.target.value);
        this.initialRelatedConveyer = event.target.value;
    }
}