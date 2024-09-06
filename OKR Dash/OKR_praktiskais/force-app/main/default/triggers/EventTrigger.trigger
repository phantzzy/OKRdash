trigger EventTrigger on Event (after insert, after update, after delete) {
    // Maps for tracking increments and decrements
    Map<Id, Map<String, Integer>> incrementMap = new Map<Id, Map<String, Integer>>();
    Map<Id, Map<String, Integer>> decrementMap = new Map<Id, Map<String, Integer>>();

    // Helper function to build the key for the Subject map

    String buildMapKey(Id keyResultId, String subject) {
        return keyResultId + ':' + subject;
    }

    // Process increment for inserted records

    if (Trigger.isInsert) {
        for (Event event : Trigger.new) {
            if (event.Key_Result__c != null && event.Subject != null) {
                if (!incrementMap.containsKey(event.Key_Result__c)) {
                    incrementMap.put(event.Key_Result__c, new Map<String, Integer>());
                }
                Map<String, Integer> subjectMap = incrementMap.get(event.Key_Result__c);
                
                if (!subjectMap.containsKey(event.Subject)) {
                    subjectMap.put(event.Subject, 1);
                } else {
                    subjectMap.put(event.Subject, subjectMap.get(event.Subject) + 1);
                }
            }
        }
    }

    // Process decrement and increment for updated records

    if (Trigger.isUpdate) {
        for (Event event : Trigger.new) {
            Event oldEvent = Trigger.oldMap.get(event.Id);
            
            // Decrement if old Key_Result__c or Subject has changed

            if (oldEvent.Key_Result__c != event.Key_Result__c || oldEvent.Subject != event.Subject) {
                if (oldEvent.Key_Result__c != null && oldEvent.Subject != null) {
                    if (!decrementMap.containsKey(oldEvent.Key_Result__c)) {
                        decrementMap.put(oldEvent.Key_Result__c, new Map<String, Integer>());
                    }
                    Map<String, Integer> subjectMap = decrementMap.get(oldEvent.Key_Result__c);
                    if (!subjectMap.containsKey(oldEvent.Subject)) {
                        subjectMap.put(oldEvent.Subject, 1);
                    } else {
                        subjectMap.put(oldEvent.Subject, subjectMap.get(oldEvent.Subject) + 1);
                    }
                }

                // Increment the new event key result

                if (event.Key_Result__c != null && event.Subject != null) {
                    if (!incrementMap.containsKey(event.Key_Result__c)) {
                        incrementMap.put(event.Key_Result__c, new Map<String, Integer>());
                    }
                    Map<String, Integer> subjectMap = incrementMap.get(event.Key_Result__c);
                    if (!subjectMap.containsKey(event.Subject)) {
                        subjectMap.put(event.Subject, 1);
                    } else {
                        subjectMap.put(event.Subject, subjectMap.get(event.Subject) + 1);
                    }
                }
            }
        }
    }

    // Process decrement for deleted records

    if (Trigger.isDelete) {
        for (Event event : Trigger.old) {
            if (event.Key_Result__c != null && event.Subject != null) {
                if (!decrementMap.containsKey(event.Key_Result__c)) {
                    decrementMap.put(event.Key_Result__c, new Map<String, Integer>());
                }
                Map<String, Integer> subjectMap = decrementMap.get(event.Key_Result__c);
                if (!subjectMap.containsKey(event.Subject)) {
                    subjectMap.put(event.Subject, 1);
                } else {
                    subjectMap.put(event.Subject, subjectMap.get(event.Subject) + 1);
                }
            }
        }
    }

    // Now perform the updates based on increment and decrement maps

    List<CustomEvent__c> customEventsToUpdate = new List<CustomEvent__c>();

    // Process increments
    if (!incrementMap.isEmpty()) {
        for (Id keyResultId : incrementMap.keySet()) {
            Map<String, Integer> subjectMap = incrementMap.get(keyResultId);
            List<CustomEvent__c> customEventsToIncrement = [
                SELECT Id, Completed_Target__c, Type__c 
                FROM CustomEvent__c 
                WHERE Key_Result__c = :keyResultId AND Type__c IN :subjectMap.keySet()
            ];

            for (CustomEvent__c customEvent : customEventsToIncrement) {
                customEvent.Completed_Target__c = (customEvent.Completed_Target__c == null) ? 1 : customEvent.Completed_Target__c + subjectMap.get(customEvent.Type__c);
                customEventsToUpdate.add(customEvent);
            }
        }
    }

    // Process decrements

    if (!decrementMap.isEmpty()) {
        for (Id keyResultId : decrementMap.keySet()) {
            Map<String, Integer> subjectMap = decrementMap.get(keyResultId);
            List<CustomEvent__c> customEventsToDecrement = [
                SELECT Id, Completed_Target__c, Type__c 
                FROM CustomEvent__c 
                WHERE Key_Result__c = :keyResultId AND Type__c IN :subjectMap.keySet()
            ];

            for (CustomEvent__c customEvent : customEventsToDecrement) {
                Integer decrementValue = subjectMap.get(customEvent.Type__c);
                customEvent.Completed_Target__c = (customEvent.Completed_Target__c > 0) ? customEvent.Completed_Target__c - decrementValue : 0;
                customEventsToUpdate.add(customEvent);
            }
        }
    }

    // Update the records
    
    if (!customEventsToUpdate.isEmpty()) {
        update customEventsToUpdate;
    }
}