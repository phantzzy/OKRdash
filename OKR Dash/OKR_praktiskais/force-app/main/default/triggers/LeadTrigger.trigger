trigger LeadTrigger on Lead (after insert, after update, after delete) {
    // Maps for tracking increments and decrements

    Map<Id, Map<String, Integer>> incrementMap = new Map<Id, Map<String, Integer>>();
    Map<Id, Map<String, Integer>> decrementMap = new Map<Id, Map<String, Integer>>();

    // Helper function to build the key for the Lead Source map

    String buildMapKey(Id keyResultId, String leadSource) {
        return keyResultId + ':' + leadSource;
    }

    // Process increment for inserted records

    if (Trigger.isInsert) {
        for (Lead lead : Trigger.new) {
            if (lead.Key_Result__c != null && lead.LeadSource != null) {
                if (!incrementMap.containsKey(lead.Key_Result__c)) {
                    incrementMap.put(lead.Key_Result__c, new Map<String, Integer>());
                }
                Map<String, Integer> leadSourceMap = incrementMap.get(lead.Key_Result__c);
                
                if (!leadSourceMap.containsKey(lead.LeadSource)) {
                    leadSourceMap.put(lead.LeadSource, 1);
                } else {
                    leadSourceMap.put(lead.LeadSource, leadSourceMap.get(lead.LeadSource) + 1);
                }
            }
        }
    }

    // Process decrement and increment for updated records

    if (Trigger.isUpdate) {
        for (Lead lead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(lead.Id);
            
            // Decrement if old Key_Result__c or LeadSource has changed

            if (oldLead.Key_Result__c != lead.Key_Result__c || oldLead.LeadSource != lead.LeadSource) {
                if (oldLead.Key_Result__c != null && oldLead.LeadSource != null) {
                    if (!decrementMap.containsKey(oldLead.Key_Result__c)) {
                        decrementMap.put(oldLead.Key_Result__c, new Map<String, Integer>());
                    }
                    Map<String, Integer> leadSourceMap = decrementMap.get(oldLead.Key_Result__c);
                    if (!leadSourceMap.containsKey(oldLead.LeadSource)) {
                        leadSourceMap.put(oldLead.LeadSource, 1);
                    } else {
                        leadSourceMap.put(oldLead.LeadSource, leadSourceMap.get(oldLead.LeadSource) + 1);
                    }
                }

                // Increment the new key result

                if (lead.Key_Result__c != null && lead.LeadSource != null) {
                    if (!incrementMap.containsKey(lead.Key_Result__c)) {
                        incrementMap.put(lead.Key_Result__c, new Map<String, Integer>());
                    }
                    Map<String, Integer> leadSourceMap = incrementMap.get(lead.Key_Result__c);
                    if (!leadSourceMap.containsKey(lead.LeadSource)) {
                        leadSourceMap.put(lead.LeadSource, 1);
                    } else {
                        leadSourceMap.put(lead.LeadSource, leadSourceMap.get(lead.LeadSource) + 1);
                    }
                }
            }
        }
    }

    // Process decrement for deleted records

    if (Trigger.isDelete) {
        for (Lead lead : Trigger.old) {
            if (lead.Key_Result__c != null && lead.LeadSource != null) {
                if (!decrementMap.containsKey(lead.Key_Result__c)) {
                    decrementMap.put(lead.Key_Result__c, new Map<String, Integer>());
                }
                Map<String, Integer> leadSourceMap = decrementMap.get(lead.Key_Result__c);
                if (!leadSourceMap.containsKey(lead.LeadSource)) {
                    leadSourceMap.put(lead.LeadSource, 1);
                } else {
                    leadSourceMap.put(lead.LeadSource, leadSourceMap.get(lead.LeadSource) + 1);
                }
            }
        }
    }

    // Now perform the updates based on increment and decrement maps

    List<CustomLead__c> customLeadsToUpdate = new List<CustomLead__c>();

    // Process increments
    if (!incrementMap.isEmpty()) {
        for (Id keyResultId : incrementMap.keySet()) {
            Map<String, Integer> leadSourceMap = incrementMap.get(keyResultId);
            List<CustomLead__c> customLeadsToIncrement = [
                SELECT Id, Completed_Target__c, Type__c 
                FROM CustomLead__c 
                WHERE Key_Result__c = :keyResultId AND Type__c IN :leadSourceMap.keySet()
            ];

            for (CustomLead__c customLead : customLeadsToIncrement) {
                customLead.Completed_Target__c = (customLead.Completed_Target__c == null) ? 1 : customLead.Completed_Target__c + leadSourceMap.get(customLead.Type__c);
                customLeadsToUpdate.add(customLead);
            }
        }
    }

    // Process decrements

    if (!decrementMap.isEmpty()) {
        for (Id keyResultId : decrementMap.keySet()) {
            Map<String, Integer> leadSourceMap = decrementMap.get(keyResultId);
            List<CustomLead__c> customLeadsToDecrement = [
                SELECT Id, Completed_Target__c, Type__c 
                FROM CustomLead__c 
                WHERE Key_Result__c = :keyResultId AND Type__c IN :leadSourceMap.keySet()
            ];

            for (CustomLead__c customLead : customLeadsToDecrement) {
                Integer decrementValue = leadSourceMap.get(customLead.Type__c);
                customLead.Completed_Target__c = (customLead.Completed_Target__c > 0) ? customLead.Completed_Target__c - decrementValue : 0;
                customLeadsToUpdate.add(customLead);
            }
        }
    }

    // Update the records
    
    if (!customLeadsToUpdate.isEmpty()) {
        update customLeadsToUpdate;
    }
}