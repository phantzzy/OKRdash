trigger ContractTrigger on Contract (after insert, after delete, after update) {

    // List to hold CustomContract__c records to update

    List<CustomContract__c> customContractsToUpdate = new List<CustomContract__c>();

    // Handle after insert to increment Completed_Target__c

    if (Trigger.isInsert) {
        for (Contract con : Trigger.new) {
            if (con.Key_Result__c != null && con.Type__c != null) {

                // Query related CustomContract__c records based on the Contract's Key_Result__c and Type

                List<CustomContract__c> relatedCustomContracts = [
                    SELECT Id, Completed_Target__c 
                    FROM CustomContract__c 
                    WHERE Key_Result__c = :con.Key_Result__c 
                    AND Type__c = :con.Type__c
                ];

                // Increment the Completed_Target__c for each related CustomContract__c record

                for (CustomContract__c customContract : relatedCustomContracts) {
                    customContract.Completed_Target__c = (customContract.Completed_Target__c == null) ? 1 : customContract.Completed_Target__c + 1;
                    customContractsToUpdate.add(customContract);
                }
            }
        }
    }

    // Handle after delete to decrement Completed_Target__c

    if (Trigger.isDelete) {
        for (Contract con : Trigger.old) {
            if (con.Key_Result__c != null && con.Type__c != null) {

                // Query related CustomContract__c records based on the Contract's Key_Result__c and Type

                List<CustomContract__c> relatedCustomContracts = [
                    SELECT Id, Completed_Target__c 
                    FROM CustomContract__c 
                    WHERE Key_Result__c = :con.Key_Result__c 
                    AND Type__c = :con.Type__c
                ];

                // Decrement the Completed_Target__c for each related CustomContract__c record

                for (CustomContract__c customContract : relatedCustomContracts) {
                    customContract.Completed_Target__c = (customContract.Completed_Target__c == null || customContract.Completed_Target__c <= 0) ? 0 : customContract.Completed_Target__c - 1;
                    customContractsToUpdate.add(customContract);
                }
            }
        }
    }

    // Handle after update to adjust Completed_Target__c based on changes

    if (Trigger.isUpdate) {
        for (Contract con : Trigger.new) {
            Contract oldCon = Trigger.oldMap.get(con.Id);

            // Check if Key_Result__c or Type has changed

            if (con.Key_Result__c != oldCon.Key_Result__c || con.Type__c != oldCon.Type__c) {

                // Decrement the old CustomContract__c record

                if (oldCon.Key_Result__c != null && oldCon.Type__c != null) {
                    List<CustomContract__c> relatedCustomContractsOld = [
                        SELECT Id, Completed_Target__c 
                        FROM CustomContract__c 
                        WHERE Key_Result__c = :oldCon.Key_Result__c 
                        AND Type__c = :oldCon.Type__c
                    ];

                    for (CustomContract__c customContract : relatedCustomContractsOld) {
                        customContract.Completed_Target__c = (customContract.Completed_Target__c == null || customContract.Completed_Target__c <= 0) ? 0 : customContract.Completed_Target__c - 1;
                        customContractsToUpdate.add(customContract);
                    }
                }

                // Increment the new CustomContract__c record

                if (con.Key_Result__c != null && con.Type__c != null) {
                    List<CustomContract__c> relatedCustomContractsNew = [
                        SELECT Id, Completed_Target__c 
                        FROM CustomContract__c 
                        WHERE Key_Result__c = :con.Key_Result__c 
                        AND Type__c = :con.Type__c
                    ];

                    for (CustomContract__c customContract : relatedCustomContractsNew) {
                        customContract.Completed_Target__c = (customContract.Completed_Target__c == null) ? 1 : customContract.Completed_Target__c + 1;
                        customContractsToUpdate.add(customContract);
                    }
                }
            }
        }
    }

    // Update the CustomContract__c records
    
    if (!customContractsToUpdate.isEmpty()) {
        update customContractsToUpdate;
    }
}