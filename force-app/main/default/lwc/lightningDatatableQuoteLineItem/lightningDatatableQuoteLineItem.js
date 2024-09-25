import { LightningElement,api,wire,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import COLORS from '@salesforce/resourceUrl/CustomDatatableStyling1';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendAndFetchQuoteIdRstkProductData from '@salesforce/apex/FetchQuoteDetailsForSalesOrder.fetchRstkProductMasterForOrderLineItem';



//define row actions
const actions = [
    { label: 'Select', name: 'select' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
 ];
export default class LightningDatatableQuoteLineItem extends LightningElement {

    @track quoteList = [];
    @track quoteColumnsData = []; 
    @track flagSendListToParent;
    @track showLightningTable;
    isCssLoaded = false;
    @track isLoading;

    //testing
    fldsItemValues = [];

    saveHandleAction(event) {

        //testing 
        this.isLoading = true;
        this.sendEventToParent(true,"showhidebutton");

        this.fldsItemValues = event.detail.draftValues;
        console.log("draft values "+JSON.stringify(this.fldsItemValues));

        const inputsItems = this.fldsItemValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        console.log("draft values "+JSON.stringify(inputsItems));
        const promises = inputsItems.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records Updated Successfully!!',
                    variant: 'success'
                })
            );
            this.fldsItemValues = [];
            this.sendEventToParent("refresh","refreshlistinlineedit");
            //return this.refresh();
        }).catch(error => {
            let msg = 'An Error Occured!!'+error
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: msg,
                    variant: 'error'
                })
            );
        }).finally(() => {
            this.fldsItemValues = [];
            //testing 
            this.isLoading = false;
            this.sendEventToParent(false,"showhidebutton");
        });
    }


    @api get quotesSelected() {
        return this.quoteList;
   }
   set quotesSelected(value) {
    this.setAttribute('quotesSelected', value);   
    this.quoteList = value;
    console.log("Value from parent kalka"+JSON.stringify(this.quoteList));
    if(Array.isArray(this.quoteList) && this.quoteList.length) {
        this.editList();
    }
}


    @api get showTable() {
        return this.showLightningTable;
    }
    set showTable(value) {
    this.setAttribute('showTable', value);   
    this.showLightningTable = value;
    console.log("Value from parent to hide or show datatable "+JSON.stringify(this.showLightningTable));
    }
    
    @api get sendListToParent() {
        return this.flagSendListToParent;
    }
    set sendListToParent(value) {
        console.log("Triggered 1");

    this.setAttribute('sendListToParent', value);   
    this.flagSendListToParent = value;
    console.log("Value from parent flag 1"+JSON.stringify(this.flagSendListToParent));
    

    if(this.flagSendListToParent === 'Yes') {
        // const selectedEvent = new CustomEvent("quoteitemlistvaluechange", {
        //     detail: this.quoteList
        //   });
      
          // Dispatches the event.
          //this.dispatchEvent(selectedEvent);
          this.sendEventToParent(this.quoteList,"quoteitemlistvaluechange");
    }
    console.log("Value from parent flag 2"+JSON.stringify(this.flagSendListToParent));
    }

    //testing
    sendEventToParent(data,eventName) {
        const selectedEvent = new CustomEvent(eventName, {
            detail: data
          });
      
          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
    }


    connectedCallback() {
        this.setColumnData();
        //loadStyle(this, datatable);

        //testing 
        this.isLoading = false;
    }

    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, COLORS).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the colors")
        })
    }

    editList() { 

        this.quoteList =   this.quoteList .map(obj => ({ ...obj, Pname: '',PrintLine: true }))
        
        let idQuoteItemIdList = [];

        for(var i = 0 ; i<this.quoteList.length ; i++) {


            //testing
            idQuoteItemIdList.push(this.quoteList[i].Product2Id);

            let prod = this.quoteList[i];
            console.log("Pname "+JSON.stringify(prod));
            let temp = prod["Product2"];
            console.log("Pname "+JSON.stringify(temp));
            console.log("Pname "+JSON.stringify(temp.Name));
            prod["Pname"] = temp.Name;
            
            prod["Clicked"] = 'Confirm';
            prod["CssClass"] = 'delete-icn';
            prod["CssClassPrintLine"] = 'print-line-yes';
            prod["Editable"] = true;
            
            //testing
            prod["RelatedRootstockProduct"] = '';

            this.quoteList[i] = prod; 
            console.log("quoteList "+JSON.stringify(this.quoteList));
        }

        this.fetchRootstockProductMaster(idQuoteItemIdList);
    }


    fetchRootstockProductMaster(idList) {
        sendAndFetchQuoteIdRstkProductData({idOrderLineList : idList})
        .then(result => {
                console.log("Rstk PM ++++ "+JSON.stringify(result));
                let rstkPMList = result;
                
                let j = 0;
                console.log("length of J "+JSON.stringify(j));

                while(j<rstkPMList.length){
                    let temp = this.quoteList;
                    for(var p = 0;p<temp.length;p++) {
                       let temp1 = temp[p]; 
                         console.log("ONE "+JSON.stringify(temp1["Product2Id"]));
                         console.log("TWO "+JSON.stringify(rstkPMList[j].rstk__soprod_sf_product__c));
                            if(temp1["Product2Id"] === rstkPMList[j].rstk__soprod_sf_product__c) {
                             console.log("Entered");
                             temp1["RelatedRootstockProduct"] = rstkPMList[j].Id; 
                             this.quoteList[p] = temp1;
                            }
                    }
                    j++;
                }

                /*while(j<rstkPMList.length){
                for(var p = 0;p<rstkPMList.length;p++) {
                    
                     let temp = this.quoteList[p];
                     console.log("ONE "+JSON.stringify(temp["Product2Id"]));
                     console.log("TWO "+JSON.stringify(rstkPMList[p].rstk__soprod_sf_product__c));
                        if(temp["Product2Id"] === rstkPMList[j].rstk__soprod_sf_product__c) {
                         console.log("Entered");
                         temp["RelatedRootstockProduct"] = rstkPMList[p].Id; 
                         this.quoteList[p] = temp;
                        break;
                        }
                }
                j++;
            }*/
                console.log("quoteList rstk "+JSON.stringify(this.quoteList));
        })
        .catch( error=>{
            console.log("Rstk PM error "+JSON.stringify(error));
            this.error = error;
            ShowToastEvent("error",this.error);
        });
    }

    setColumnData() {
      this.quoteColumnsData =  
      [ 
        {type: "button-icon", typeAttributes: {  
            iconName: 'action:delete',
            variant: 'bare',
            iconClass: {fieldName:'CssClass'},
            name: 'DELETE',  
            title: 'Delete',  
            disabled: false,  
            value: 'delete',  
            iconPosition: 'left'  
        }},
        { label: 'Product Name', fieldName: 'Pname', type: 'text',editable:{fieldName:'Editable'},wrapText: true },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number',editable:{fieldName:'Editable'}},
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency',editable:{fieldName:'Editable'}},
        { label: 'Description', fieldName: 'Description__c', type: 'text',editable:{fieldName:'Editable'},wrapText: true},
        { label: 'Requested Ship Date', fieldName: 'ServiceDate', type: 'date',editable:{fieldName:'Editable'},wrapText: true},
        { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency'},
        { label: 'Related Conveyor', fieldName: 'relatedConveyorName', type: 'text'},
        { label: 'End Customer', fieldName: 'endCustomerName', type: 'text'},
        // Action button
        {label: 'Print Line',type: "button-icon", typeAttributes: {  
            iconName: 'utility:check',  
            variant:'border-filled',
            name: 'PrintLine',  
            title: 'PrintLine',  
            iconClass: {fieldName:'CssClassPrintLine'},
            disabled: false,  
            value: 'view',  
            iconPosition: 'left'  
        }},
        // Action button
        {label: 'Confirm Line',type: "button", typeAttributes: {  
            label: {fieldName: 'Clicked'},  
            name: 'Confirm',  
            title: 'Confirm',  
            disabled: false,  
            value: 'view',  
            iconPosition: 'left'  
        }}
    ];
    }

    
    addRelated (event) {
        let title = event.target.title;
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        let idClicked = row.Id;

        console.log("title "+JSON.stringify(title));
        console.log("actionName "+JSON.stringify(actionName));
        console.log("row "+JSON.stringify(row));
        console.log("idClicked "+JSON.stringify(idClicked));

        switch(actionName) {

            case 'DELETE':
                let temp = this.quoteList.filter(each => each.Id != idClicked);
                this.quoteList = temp;

                //testing
                if(!this.quoteList.length) {
                    this.sendEventToParent(false,"alldeleted");
                }

                console.log("Temp "+JSON.stringify(temp));    
            break;

            case 'Confirm':
                console.log("Confirm clicked");
                for(var j = 0 ;j<this.quoteList.length;j++) {
                    if(idClicked === this.quoteList[j].Id) {
                        console.log("Reached");
                        let temp1 = this.quoteList[j];
                        if(temp1["Clicked"] === 'Confirm') {
                            temp1["Clicked"] = "Unconfirm";
                            temp1["Editable"] = false;    
                        }
                        else if(temp1["Clicked"] === 'Unconfirm') {
                             temp1["Clicked"] = "Confirm";
                             temp1["Editable"] = true;    
                        }
                        this.quoteList[j] = temp1;
                    }
                }
                this.quoteList = this.quoteList.slice();
                console.log("quote List "+JSON.stringify(this.quoteList));  
                break;       
                
                case 'PrintLine':
                    console.log("Print line clicked");
                    for(var k = 0 ;k<this.quoteList.length;k++) {
                        if(idClicked === this.quoteList[k].Id) {
                            console.log("Reached");
                            let temp1 = this.quoteList[k];
                            if(temp1["CssClassPrintLine"] === 'print-line-yes') {
                                temp1["CssClassPrintLine"] = "print-line-no";
                                temp1["PrintLine"] = false;
                            }
                            else if(temp1["CssClassPrintLine"] === 'print-line-no') {
                                 temp1["CssClassPrintLine"] = "print-line-yes";
                                 temp1["PrintLine"] = true;
                            }
                            this.quoteList[k] = temp1;
                        }
                    }
                    this.quoteList = this.quoteList.slice();
                    console.log("quote List "+JSON.stringify(this.quoteList)); 
                break;
        }


        /*if(actionName === 'DELETE') {
            let temp = this.quoteList.filter(each => each.Id != idClicked);
            this.quoteList = temp;
            console.log("Temp "+JSON.stringify(temp));
        }
        
        if(actionName === 'Confirm') {
            //event.detail.action.label = 'Unconfirm';
            console.log("Reached Confirm"); 
            
            for(var j = 0 ;j<this.quoteList.length;j++) {
                if(idClicked === this.quoteList[j].Id) {
                    console.log("Reached");
                    let temp1 = this.quoteList[j];
                    temp1["Clicked"] = "Unconfirm";
                    this.quoteList[j] = temp1;
                }
            }
            console.log("quote List "+JSON.stringify(this.quoteList));
        }*/
     }




}