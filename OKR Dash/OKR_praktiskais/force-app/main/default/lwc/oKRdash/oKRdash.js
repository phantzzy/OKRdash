import { LightningElement, track, wire } from 'lwc';
import getKeyResults from '@salesforce/apex/OKRController.getKeyResults';
import createReview from '@salesforce/apex/OKRController.createReview';
import createSurvey from '@salesforce/apex/OKRController.createSurvey';
import createCaseStudy from '@salesforce/apex/OKRController.createCaseStudy';
import createGoogleReview from '@salesforce/apex/OKRController.createGoogleReview';
import createKeyResult from '@salesforce/apex/OKRController.createKeyResult';
import createCall from '@salesforce/apex/OKRController.createCall';
import createCustomEvent from '@salesforce/apex/OKRController.createCustomEvent';
import createLead from '@salesforce/apex/OKRController.createLead';
import createContract from '@salesforce/apex/OKRController.createContract';
import createOpportunity from '@salesforce/apex/OKRController.createOpportunity';
import getObjectives from '@salesforce/apex/OKRController.getObjectives';
import getActiveUsers from '@salesforce/apex/OKRController.getActiveUsers';
import getPicklistValues from '@salesforce/apex/OKRController.getPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class OkrDashboard extends LightningElement {

    @track objectives = [];
    @track selectedYear = '2024';  
    @track yearOptions = [];
    @track selectedYearFormatted = ''; // Store formatted year as YYYY-01-01
    @track selectedUser = ''; 
    @track showNewObjectiveModal = false;
    @track showNewKeyResultModal = false;
    @track showNewReviewModal = false;
    @track showNewSurveyModal = false;
    @track showNewGoogleReviewModal = false;
    @track showNewCaseStudyModal = false;

    @track googleReviewType = '';
    @track googleReviewTypeOptions = [];
    @track selectedGoogleReviewType = ''; 

    @track reviewType = '';
    @track reviewTypeOptions = [];
    @track selectedReviewType = ''; 

    @track surveyType = '';
	@track surveyTypeOptions = []; 
	@track selectedSurveyType = '';
    
    @track callType = '';
    @track callTypeOptions = [];
    @track selectedCallType = '';
    @track showNewCallModal = false;

    @track showNewLeadModal = false;
    @track leadType = '';
    @track selectedLeadType = '';
    @track leadName = '';
    @track customLeadTypeOptions = [];

    @track showNewContractModal = false;
    @track contractName = '';
    @track contractType = '';
    @track selectedContractType = '';
    @track customContractTypeOptions = [];

    @track customEventName = '';
    @track customEventType = '';
    @track customEventTypeOptions = []; 
	@track selectedCustomEventType = '';
    @track showNewCustomEventModal = false;

    @track showNewOpportunityModal = false;
    @track opportunityType = '';
    @track selectedOpportunityType = '';
    @track opportunityName = '';
    @track opportunityTypeOptions = []; 

    @track showNewSurveyRecordModal = false;

    @track userOptions = [];

    @track caseStudyName = '';
    @track caseStudyType = '';
    @track caseStudyTypeOptions = [];
    @track selectedCaseStudyType = ''; 

    @track keyResultOptions = []; 
    @track selectedKeyResultId = ''; 
    @track selectedTarget = 0; 
    @track selectedCompletedTarget = 0; 


    @wire(getObjectives, { year: '$selectedYear', userId: '$selectedUser' })
    wiredObjectives({ error, data }) {
        if (data) {
            this.objectives = data;
        } else if (error) {
            console.error('Error loading objectives:', error);
            this.objectives = [];
            this.showToast('Error', 'Failed to load objectives', 'error');
        }
    }

    @wire(getActiveUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));

            this.selectedUser = this.userOptions.length > 0 ? this.userOptions[0].value : '';
        } else if (error) {
            console.error('Error loading users:', error);
        }
    }

    @wire(getPicklistValues, { objectApiName: 'Call__c', fieldApiName: 'Type__c' })
    wiredCallTypePicklist({ error, data }) {
        if (data) {
            this.callTypeOptions = data.map(picklist => ({
                label: picklist.label,
                value: picklist.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    @wire(getKeyResults)
    wiredKeyResults({ error, data }) {
        if (data) {
            this.objectives = data.map(objective => {
                return {
                    ...objective,
                    Reviews__r: this.processRecords(objective.Reviews__r),
                    Surveys__r: this.processRecords(objective.Surveys__r),
                    Google_Reviews__r: this.processRecords(objective.Google_Reviews__r),
                    Calls__r: this.processRecords(objective.Calls__r),
                    CustomLeads__r: this.processRecords(objective.CustomLeads__r),
                    CustomContracts__r: this.processRecords(objective.CustomContracts__r),
                    Case_Studies__r: this.processRecords(objective.Case_Studies__r),
                    CustomEvents__r: this.processRecords(objective.CustomEvents__r),
                    CustomOpportunities__r: this.processRecords(objective.CustomOpportunities__r)
                };
            });
            this.noObjectives = this.objectives.length === 0;
        } else if (error) {
            this.objectives = [];
            this.noObjectives = true;
        }
    }

    // Dropdown options

    get modalOptions() {
        return [

            { label: 'New Review', value: 'newReview' },
            { label: 'New Survey', value: 'newSurvey' },
            { label: 'New Google Review', value: 'newGoogleReview' },
            { label: 'New Case Study', value: 'newCaseStudy' },
            { label: 'New Call', value: 'newCall' },
            { label: 'New Lead', value: 'newLead' },
            { label: 'New Contract', value: 'newContract' },
            { label: 'New Opportunity', value: 'newOpportunity' },
            { label: 'New Custom Event', value: 'newCustomEvent' }//,

        ];
    }

    get recordOptions() {
        return [
            { label: 'New Objective', value: 'newObjective' },
            { label: 'New Key Result', value: 'newKeyResult' },
            { label: 'New Survey Record', value: 'newSurveyRecord' },
        ];
    }

    // Handle the selection from the combobox

    handleRecordSelection(event) {
        this.closeModal(); 
        const selectedRecord = event.detail.value;

        switch (selectedRecord) {
           
            case 'newObjective':
                this.showNewObjectiveModal = true;
                break;
            case 'newKeyResult':
                this.showNewKeyResultModal = true;
                break; 
            case 'newSurveyRecord':
                this.showNewSurveyRecordModal = true;
                break;
            default:
                break;
        }
    }

connectedCallback() {
    // Create year options dynamically (for example, from 2024 to 2054)

    const currentYear = new Date().getFullYear();
    for (let i = currentYear; i <= currentYear + 30; i++) {
        this.yearOptions.push({ label: i.toString(), value: i.toString() });
    }
}

// Handle closing the modal

handleCloseModal() {
    this.showNewSurveyRecordModal = false;
}

handleSelect(event) {
    const selectedItemValue = event.detail.value;
    
    if (selectedItemValue === 'surveyRecord') {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'SurveyRecord__c',
                actionName: 'new'
            }
        });
    }
}

handleModalSelection(event) {
    this.closeModal();  // Close any open modals first
    const selectedModal = event.detail.value;

    switch (selectedModal) {
        case 'newReview':
            this.showNewReviewModal = true;
            break;
        case 'newSurvey':
            this.showNewSurveyModal = true;
            break;
        case 'newGoogleReview':
            this.showNewGoogleReviewModal = true;
            break;
        case 'newCaseStudy':
            this.showNewCaseStudyModal = true;
            break;
        case 'newCall':
            this.showNewCallModal = true;
            break;
        case 'newLead':
            this.showNewLeadModal = true;
            break;
        case 'newContract':
            this.showNewContractModal = true;
            break;
        case 'newOpportunity':
            this.showNewOpportunityModal = true;
            break;
        case 'newCustomEvent':
            this.showNewCustomEventModal = true;
            break;
        default:
            break;
    }
}

    processRecords(records) {
        return records ? records.map(record => ({
            ...record,
            displayName: record.Name // Use Name as the display name
        })) : [];
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value; // Update the selected year
        this.selectedYearFormatted = `${this.selectedYear}-01-01`; // Format the year for Salesforce
    }

    handleUserChange(event) {
        this.selectedUser = event.detail.value;
    }

    handleNewObjective() {
        this.showNewObjectiveModal = true;
    }

    handleNewKeyResult() {
        this.showNewKeyResultModal = true;
    }

    handleNewReview() {
        this.showNewReviewModal = true;
    }

    handleNewSurvey() {
        this.showNewSurveyModal = true;
    }

    handleSurveyTypeChange(event) {
        this.selectedSurveyType = event.detail.value;
    }

    handleNewContract() {
        this.showNewContractModal = true;
    }

    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
    }

    handleSaveContract() {
        if (!this.contractName || !this.selectedContractType) {
            this.showToast('Error', 'Please provide all required fields', 'error');
            return;
        }

        const contractData = {
            contractName: this.contractName,
            contractType: this.selectedContractType
        };

        createContract({ contractData })
            .then(() => {
                this.showToast('Success', 'Contract successfully created', 'success');
                this.handleCloseNewContractModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the contract', 'error');
            });
    }

    handleCloseNewContractModal() {
        this.showNewContractModal = false;
        this.contractName = '';
        this.selectedContractType = '';
    }

    handleNewOpportunity() {
        this.showNewOpportunityModal = true;
    }

    handleOpportunityTypeChange(event) {
        this.selectedOpportunityType = event.detail.value;
    }

    handleSaveOpportunity() {
        if (!this.opportunityName || !this.selectedOpportunityType || !this.keyResultId) {
            this.showToast('Error', 'Please provide an opportunity name, type, and key result', 'error');
            return;
        }

        const opportunityData = {
            opportunityName: this.opportunityName,
            opportunityType: this.selectedOpportunityType,
            target: this.target,
            completedTarget: this.completedTarget,
            keyResultId: this.keyResultId
        };

        createOpportunity({ opportunityData })
            .then(() => {
                this.showToast('Success', 'Opportunity successfully created', 'success');
                this.handleCloseNewOpportunityModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the opportunity', 'error');
            });
    }

    handleCloseNewOpportunityModal() {
        this.showNewOpportunityModal = false;
        this.opportunityName = '';
        this.target = 0;
        this.completedTarget = 0;
        this.selectedOpportunityType = '';
        this.keyResultId = '';
    }

    handleNewLead() {
        this.showNewLeadModal = true;
    }

    handleLeadTypeChange(event) {
        this.selectedLeadType = event.detail.value;
    }

    handleSaveLead() {
        if (!this.leadName || !this.selectedLeadType) {
            this.showToast('Error', 'Please provide a lead name and type', 'error');
            return;
        }

        const leadData = {
            leadName: this.leadName,
            leadType: this.selectedLeadType,
            target: this.target,
            completedTarget: this.completedTarget
        };

        createLead({ leadData })
            .then(() => {
                this.showToast('Success', 'Lead successfully created', 'success');
                this.handleCloseNewLeadModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the lead', 'error');
            });
    }

    handleCloseNewLeadModal() {
        this.showNewLeadModal = false;
        this.leadName = '';
        this.target = 0;
        this.completedTarget = 0;
        this.selectedLeadType = '';
    }

    handleNewGoogleReview() {
        this.showNewGoogleReviewModal = true;
    }

    handleGoogleReviewTypeChange(event) {
        this.selectedGoogleReviewType = event.detail.value;
    }

    handleSaveGoogleReview() {
        if (!this.selectedGoogleReviewType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a google review type and key result', 'error');
            return;
        }
    
        const googleReviewData = {
            keyResultId: this.selectedKeyResultId,
            googleReviewName: this.selectedGoogleReviewType,
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };
    
        createGoogleReview({ googleReviewData })
            .then(() => {
                this.showToast('Success', 'Google Review successfully created', 'success');
                this.handleCloseNewGoogleReviewModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the google reivew', 'error');
            });
    }

    handleCloseNewGoogleReviewModal() {
        this.showNewGoogleReviewModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedGoogleReviewType = '';
    }
    
    handleNewCall() {
        this.showNewCallModal = true;
    }    

    handleCallTypeChange(event) {
        this.selectedCallType = event.detail.value;
    }

    handleCallSuccess(event) {
        this.showNewCallModal = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Call Target created successfully',
                variant: 'success',
            }),
        );
    }

    handleSaveCall() {
        if (!this.selectedCallType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a call type and key result', 'error');
            return;
        }

        const callData = {
            keyResultId: this.selectedKeyResultId,
            callName: this.selectedCallType,
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };

        createCall({ callData })
            .then(() => {
                this.showToast('Success', 'Call successfully created', 'success');
                this.handleCloseNewCallModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the call', 'error');
            });
    }

    handleCloseNewCallModal() {
        this.showNewCallModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedCallType = '';
    }

    handleNewCaseStudy() {
        this.showNewCaseStudyModal = true;
    }



    handleCaseStudyTypeChange(event) {
        this.selectedCaseStudyType = event.detail.value;
    }

    handleSaveCaseStudy() {
        if (!this.selectedCaseStudyType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a case study type and key result', 'error');
            return;
        }
    
        const caseStudyData = {
            keyResultId: this.selectedKeyResultId,
            caseStudyName: this.selectedCaseStudyType, 
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };
    
        createCaseStudy({ caseStudyData })
            .then(() => {
                this.showToast('Success', 'Case Study successfully created', 'success');
                this.handleCloseNewCaseStudyModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the case study', 'error');
            });
    }

    handleCloseNewCaseStudyModal() {
        this.showNewCaseStudyModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedCaseStudyType = '';
    }

    handleCallTargetChange(event) {
        this.newCallTarget = event.detail.value;
    }

    handleCallCompletedTargetChange(event) {
        this.newCallCompleted = event.detail.value;
    }

    handleNewCustomEvent() {
        this.showNewCustomEventModal = true;
    }

    handleCustomEventTypeChange(event) {
        this.selectedCustomEventType = event.detail.value;
    }

    handleSaveCustomEvent() {
        if (!this.selectedCustomEventType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a event type and key result', 'error');
            return;
        }
    
        const customEventData = {
            keyResultId: this.selectedKeyResultId,
            customEventName: this.selectedCustomEventType, 
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };
    
        createCustomEvent({ customEventData })
            .then(() => {
                this.showToast('Success', 'Event successfully created', 'success');
                this.handleCloseNewCustomEventModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the event', 'error');
            });
    }

    handleCloseNewCustomEventModal() {
        this.showNewCustomEventModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedCustomEventType = '';
    }

    handleSaveKeyResult() {
        const keyResultFields = this.template.querySelector('lightning-record-edit-form').submit();

        createKeyResult({ kr: keyResultFields, calls: this.calls, events: this.events })
            .then(() => {
                this.showToast('Success', 'Key Result and related records successfully created', 'success');
                this.closeModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the record', 'error');
            });
    }
    
    handleSaveSurvey() {
        if (!this.selectedSurveyType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a survey type and key result', 'error');
            return;
        }
    
        const surveyData = {
            keyResultId: this.selectedKeyResultId,
            surveyName: this.selectedSurveyType, 
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };
    
        createSurvey({ surveyData })
            .then(() => {
                this.showToast('Success', 'Survey successfully created', 'success');
                this.handleCloseNewSurveyModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the survey', 'error');
            });
    }
    

    handleKeyResultChange(event) {
        this.selectedKeyResultId = event.detail.value;
    }

    handleTargetChange(event) {
        this.selectedTarget = event.target.value;
    }

    handleCompletedTargetChange(event) {
        this.selectedCompletedTarget = event.target.value;
    }

    handleReviewTypeChange(event) {
        this.selectedReviewType = event.detail.value;
    }

    handleSaveReview() {
        if (!this.selectedReviewType || !this.selectedKeyResultId) {
            this.showToast('Error', 'Please select a review type and key result', 'error');
            return;
        }

        const reviewData = {
            keyResultId: this.selectedKeyResultId,
            reviewName: this.selectedReviewType, 
            target: this.selectedTarget,
            completedTarget: this.selectedCompletedTarget
        };

        createReview({ reviewData })
            .then(() => {
                this.showToast('Success', 'Review successfully created', 'success');
                this.handleCloseNewReviewModal();
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while saving the review', 'error');
            });
    }

    handleCloseNewGoogleReviewModal() {
        this.showNewGoogleReviewModal = false;
    }

    handleCloseNewCaseStudyModal() {
        this.showNewCaseStudyModal = false;
    }

    handleCloseNewObjectiveModal() {
        this.showNewObjectiveModal = false;
    }

    handleCloseNewKeyResultModal() {
        this.showNewKeyResultModal = false;
    }

    handleCloseNewReviewModal() {
        this.showNewReviewModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedReviewType = '';
    }

    handleCloseNewSurveyModal() {
        this.showNewSurveyModal = false;
        this.selectedKeyResultId = '';
        this.selectedTarget = 0;
        this.selectedCompletedTarget = 0;
        this.selectedSurveyType = '';
    }

    closeModal() {
        this.showNewObjectiveModal = false;
        this.showNewKeyResultModal = false;
        this.showNewReviewModal = false;
        this.showNewSurveyModal = false;
        this.showNewCaseStudyModal = false;
        this.showNewGoogleReviewModal = false;
    }

    handleSuccess(event) {
        this.showToast('Success', 'Record saved successfully!', 'success');
        this.closeModal();
    }

    handleError(event) {
        this.showToast('Error', 'Error saving record.', 'error');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
