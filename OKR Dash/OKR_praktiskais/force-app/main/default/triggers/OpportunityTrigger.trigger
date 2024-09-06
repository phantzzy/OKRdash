trigger OpportunityTrigger on Opportunity (after insert, after delete, after update) {

    // List to store CustomOpportunity__c records to update

    List<CustomOpportunity__c> customOpportunitiesToUpdate = new List<CustomOpportunity__c>();

    // Handle after insert to increment Completed_Target__c

    if (Trigger.isInsert) {
        for (Opportunity opp : Trigger.new) {
            if (opp.Key_Result__c != null) {

                // Query related CustomOpportunity__c based on Key_Result__c 

                List<CustomOpportunity__c> relatedCustomOpportunities = [
                    SELECT Id, Completed_Target__c 
                    FROM CustomOpportunity__c 
                    WHERE Key_Result__c = :opp.Key_Result__c
                ];

                // Increment Completed_Target__c for related CustomOpportunity__c

                for (CustomOpportunity__c customOpp : relatedCustomOpportunities) {
                    customOpp.Completed_Target__c = (customOpp.Completed_Target__c == null) ? 1 : customOpp.Completed_Target__c + 1;
                    customOpportunitiesToUpdate.add(customOpp);
                }
            }
        }
    }

    // Handle after delete to decrement Completed_Target__c

    if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            if (opp.Key_Result__c != null) {

                // Query related CustomOpportunity__c based on Key_Result__c 

                List<CustomOpportunity__c> relatedCustomOpportunities = [
                    SELECT Id, Completed_Target__c 
                    FROM CustomOpportunity__c 
                    WHERE Key_Result__c = :opp.Key_Result__c
                ];

                // Decrement Completed_Target__c for related CustomOpportunity__c

                for (CustomOpportunity__c customOpp : relatedCustomOpportunities) {
                    customOpp.Completed_Target__c = (customOpp.Completed_Target__c == null || customOpp.Completed_Target__c <= 0) ? 0 : customOpp.Completed_Target__c - 1;
                    customOpportunitiesToUpdate.add(customOpp);
                }
            }
        }
    }

    // Handle after update to adjust Completed_Target__c based on changes

    if (Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

            // Check if Key_Result__c has changed

            if (opp.Key_Result__c != oldOpp.Key_Result__c) {

                // Decrement the old CustomOpportunity__c record

                if (oldOpp.Key_Result__c != null) {
                    List<CustomOpportunity__c> relatedCustomOpportunitiesOld = [
                        SELECT Id, Completed_Target__c 
                        FROM CustomOpportunity__c 
                        WHERE Key_Result__c = :oldOpp.Key_Result__c
                    ];

                    for (CustomOpportunity__c customOpp : relatedCustomOpportunitiesOld) {
                        customOpp.Completed_Target__c = (customOpp.Completed_Target__c == null || customOpp.Completed_Target__c <= 0) ? 0 : customOpp.Completed_Target__c - 1;
                        customOpportunitiesToUpdate.add(customOpp);
                    }
                }

                // Increment the new CustomOpportunity__c record

                if (opp.Key_Result__c != null) {
                    List<CustomOpportunity__c> relatedCustomOpportunitiesNew = [
                        SELECT Id, Completed_Target__c 
                        FROM CustomOpportunity__c 
                        WHERE Key_Result__c = :opp.Key_Result__c
                    ];

                    for (CustomOpportunity__c customOpp : relatedCustomOpportunitiesNew) {
                        customOpp.Completed_Target__c = (customOpp.Completed_Target__c == null) ? 1 : customOpp.Completed_Target__c + 1;
                        customOpportunitiesToUpdate.add(customOpp);
                    }
                }
            }
        }
    }

    // Update CustomOpportunity__c records
    
    if (!customOpportunitiesToUpdate.isEmpty()) {
        update customOpportunitiesToUpdate;
    }
}