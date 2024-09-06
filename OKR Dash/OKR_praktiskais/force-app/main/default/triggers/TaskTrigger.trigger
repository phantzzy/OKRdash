trigger TaskTrigger on Task (after insert, after update, after delete) {

    // List to hold Call__c records to update

    List<Call__c> callsToUpdate = new List<Call__c>();
    
    // Maps to hold Key_Result__c values for efficient updates

    Map<Id, String> keyResultsBeforeUpdate = new Map<Id, String>();
    Map<Id, String> keyResultsAfterUpdate = new Map<Id, String>();

    // Process records inserted

    if (Trigger.isInsert) {
        for (Task task : Trigger.new) {
            if (task.Subject == 'Call' && task.Key_Result__c != null) {
                List<Call__c> relatedCalls = [
                    SELECT Id, Completed_Target__c
                    FROM Call__c
                    WHERE Key_Result__c = :task.Key_Result__c
                    LIMIT 1
                ];

                if (!relatedCalls.isEmpty()) {
                    Call__c relatedCall = relatedCalls[0];
                    if (relatedCall.Completed_Target__c == null) {
                        relatedCall.Completed_Target__c = 1;
                    } else {
                        relatedCall.Completed_Target__c += 1;
                    }
                    callsToUpdate.add(relatedCall);
                }
            }
        }
    }

    // Process records updated

    if (Trigger.isUpdate) {

        // Capture old and new Key_Result__c values

        for (Task task : Trigger.old) {
            if (task.Subject == 'Call' && task.Key_Result__c != null) {
                keyResultsBeforeUpdate.put(task.Id, task.Key_Result__c);
            }
        }
        for (Task task : Trigger.new) {
            if (task.Subject == 'Call' && task.Key_Result__c != null) {
                keyResultsAfterUpdate.put(task.Id, task.Key_Result__c);
            }
        }

        for (Id taskId : keyResultsBeforeUpdate.keySet()) {
            String keyResultBefore = keyResultsBeforeUpdate.get(taskId);
            String keyResultAfter = keyResultsAfterUpdate.get(taskId);

            if (keyResultBefore != keyResultAfter) {

                // Decrement the count for the old Key_Result__c

                if (keyResultBefore != null) {
                    List<Call__c> relatedCallsBefore = [
                        SELECT Id, Completed_Target__c
                        FROM Call__c
                        WHERE Key_Result__c = :keyResultBefore
                        LIMIT 1
                    ];

                    if (!relatedCallsBefore.isEmpty()) {
                        Call__c relatedCallBefore = relatedCallsBefore[0];
                        if (relatedCallBefore.Completed_Target__c != null) {
                            relatedCallBefore.Completed_Target__c -= 1;
                            callsToUpdate.add(relatedCallBefore);
                        }
                    }
                }

                // Increment the count for the new Key_Result__c

                if (keyResultAfter != null) {
                    List<Call__c> relatedCallsAfter = [
                        SELECT Id, Completed_Target__c
                        FROM Call__c
                        WHERE Key_Result__c = :keyResultAfter
                        LIMIT 1
                    ];

                    if (!relatedCallsAfter.isEmpty()) {
                        Call__c relatedCallAfter = relatedCallsAfter[0];
                        if (relatedCallAfter.Completed_Target__c == null) {
                            relatedCallAfter.Completed_Target__c = 1;
                        } else {
                            relatedCallAfter.Completed_Target__c += 1;
                        }
                        callsToUpdate.add(relatedCallAfter);
                    }
                }
            }
        }
    }

    // Process records deleted

    if (Trigger.isDelete) {
        for (Task task : Trigger.old) {
            if (task.Subject == 'Call' && task.Key_Result__c != null) {
                List<Call__c> relatedCalls = [
                    SELECT Id, Completed_Target__c
                    FROM Call__c
                    WHERE Key_Result__c = :task.Key_Result__c
                    LIMIT 1
                ];

                if (!relatedCalls.isEmpty()) {
                    Call__c relatedCall = relatedCalls[0];
                    if (relatedCall.Completed_Target__c != null) {
                        relatedCall.Completed_Target__c -= 1;
                        callsToUpdate.add(relatedCall);
                    }
                }
            }
        }
    }

    // Update the Call__c records if there are changes
    
    if (!callsToUpdate.isEmpty()) {
        update callsToUpdate;
    }
}