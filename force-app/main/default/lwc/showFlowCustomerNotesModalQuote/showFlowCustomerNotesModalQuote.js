import { LightningElement,api,wire,track } from 'lwc';

export default class ShowFlowCustomerNotesModalQuote extends LightningElement {

    @track isModalOpen; 
    @track accountId = "";
    @track customerNotes = "";

     //testing
     get inputVariables() {
        return [
            {
                name: 'accountId',
                type: 'String',
                value: this.accountId
            }
        ];
    }
    
        @api get  receiveAccountData() {
            return this.accountId;
    }
    set receiveAccountData(value) {
        this.setAttribute('receiveAccountData', value);   
        this.accountId = value;
        console.log("Value from parent flow "+JSON.stringify(this.accountId));
    } 

    @api get  handleModalOpenClose() {
        return this.isModalOpen;
    }
    set handleModalOpenClose(value) {
    this.setAttribute('handleModalOpenClose', value);   
    this.isModalOpen = value;
    console.log("Value from parent flow open close modal "+JSON.stringify(this.isModalOpen));
    }

handleStatusChange(event) {

    //testing current
    if(event.detail.status === 'STARTED'){
        console.log("Started");
    }
    //testing current

    if(event.detail.status === 'FINISHED'){
        const outputVariables = event.detail.outputVariables;
        console.log('output variables '+JSON.stringify(outputVariables));
        for(let i = 0; i < outputVariables.length; i++) {
            const outputVar = outputVariables[i];
            if(outputVar.name == 'customerNotesOutput'){
                console.log("OUTPUT "+outputVar.value);
                console.log("OUTPUT "+JSON.stringify(outputVar.value));

                if(outputVar.value) {
                    let str = (outputVar.value).toString();
                    console.log("Str "+str);
                    let my_new_string = str.replaceAll("p","li");
                    console.log("my_new_string "+my_new_string);
                    let strNew = my_new_string.replace(",","");
                    this.customerNotes = strNew;
                }
                else{
                    this.handleModal();
                }
                

                if(this.customerNotes) {
                    this.handleModal();
                }
                //this.customerNotes = str;
                console.log("Customer Notes "+JSON.stringify(this.customerNotes));
            }
        }
    }
}

    handleModal() {
        console.log("Clicked close");
        let data = {modalStatus:false,customerNotes:this.customerNotes};
        this.sendEventToParent(data,"modalclosed");
    }

    sendEventToParent(data,eventName) {
        const selectedEvent = new CustomEvent(eventName, {
            detail: data
          });
      
          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
    }
}