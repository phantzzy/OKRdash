trigger SurveyRecordTrigger on SurveyRecord__c (after insert) {
    Set<Id> keyResultIds = new Set<Id>();

    // Collect Key Result IDs from the newly inserted SurveyRecords

    for (SurveyRecord__c sr : Trigger.new) {
        if (sr.Key_Result__c != null) {
            keyResultIds.add(sr.Key_Result__c);
        }
    }

    // Fetch Surveys that are associated with the Key Results in the SurveyRecords

    List<Survey__c> surveys = new List<Survey__c>();
    if (!keyResultIds.isEmpty()) {
        surveys = [SELECT Id, Completed_Target__c, Key_Result__c, Type__c
                   FROM Survey__c 
                   WHERE Key_Result__c IN :keyResultIds];
    }

    // Create a map to store surveys by Key Result ID and Type

    Map<Id, Map<String, Survey__c>> surveyMap = new Map<Id, Map<String, Survey__c>>();

    for (Survey__c survey : surveys) {
        if (!surveyMap.containsKey(survey.Key_Result__c)) {
            surveyMap.put(survey.Key_Result__c, new Map<String, Survey__c>());
        }
        surveyMap.get(survey.Key_Result__c).put(survey.Type__c, survey);
    }

    // Increment Completed_Target__c for related Surveys

    List<Survey__c> surveysToUpdate = new List<Survey__c>();
    for (SurveyRecord__c sr : Trigger.new) {
        if (sr.Key_Result__c != null && sr.Type__c != null && surveyMap.containsKey(sr.Key_Result__c)) {
            Survey__c surveyToUpdate = surveyMap.get(sr.Key_Result__c).get(sr.Type__c);
            if (surveyToUpdate != null) {
                surveyToUpdate.Completed_Target__c = (surveyToUpdate.Completed_Target__c == null) ? 1 : surveyToUpdate.Completed_Target__c + 1;
                surveysToUpdate.add(surveyToUpdate);
            }
        }
    }

    // Update the surveys
    
    if (!surveysToUpdate.isEmpty()) {
        update surveysToUpdate;
    }
}