public with sharing class OKRController {
    @AuraEnabled(cacheable=true)
public static List<Objective__c> getObjectives(Integer year, String userId) {
    String query = 'SELECT Id, Name, Objective_Year__c, Assigned_User__c, Status__c, ' +
                   '(SELECT Id, Name, ' +
                   '   (SELECT Id, Name, GoalTarget__c, GoalCompleted__c FROM Goals__r), ' + // Fetch related Calls with target and completed target
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM Calls__r), ' + // Fetch related Calls with target and completed target
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM CustomEvents__r), ' + // Fetch related Events with target and completed target
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM Reviews__r), ' + // Fetch related Reviews
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM Google_Reviews__r), ' + // Fetch related Google Reviews
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM Case_Studies__r), ' + // Fetch related Case Studies
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM Surveys__r), ' + // Fetch related Surveys
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM CustomOpportunities__r), ' + // Fetch related Opportunities with target and completed target
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM CustomContracts__r), ' + // Fetch related Contracts with target and completed target
                   '   (SELECT Id, Name, Type__c, Target__c, Completed_Target__c FROM CustomLeads__r) ' + // Fetch related Leads with target and completed target
                   'FROM Key_Results__r) ' +
                   'FROM Objective__c WHERE Objective_Year__c != null';
    
    if (year != null) {
        query += ' AND CALENDAR_YEAR(Objective_Year__c) = ' + year; // Directly compare year
    }
    
    if (!String.isBlank(userId)) {
        query += ' AND Assigned_User__c = \'' + String.escapeSingleQuotes(userId) + '\'';
    }
    
    return Database.query(query);
}

  
    @AuraEnabled(cacheable=true)
public static List<Key_Result__c> getKeyResults() {
    return [
        SELECT Id, Name,
            (SELECT Id, Name FROM Calls__r),
            (SELECT Id, Name FROM CustomEvents__r),
            (SELECT Id, Name FROM Reviews__r),
            (SELECT Id, Name FROM Google_Reviews__r),
            (SELECT Id, Name FROM Case_Studies__r),
            (SELECT Id, Name FROM Surveys__r),
            (SELECT Id, Name FROM CustomOpportunities__r),
            (SELECT Id, Name FROM CustomContracts__r),
            (SELECT Id, Name FROM CustomLeads__r)
        FROM Key_Result__c
    ];
}
  
      @AuraEnabled
      public static void createReview(Map<String, Object> reviewData) {

          // Create a new Review target

          Review__c newReview = new Review__c(
              Name = (String) reviewData.get('reviewName'),
              Key_Result__c = (String) reviewData.get('keyResultId'),
              Target__c = (Decimal) reviewData.get('target'),
              Completed_Target__c = (Decimal) reviewData.get('completedTarget')
          );
  
          insert newReview;
      }
  
      @AuraEnabled
      public static void createSurvey(Map<String, Object> surveyData) {

          // Create a new Survey target

          Survey__c newSurvey = new Survey__c(
              Name = (String) surveyData.get('surveyName'),
              Key_Result__c = (String) surveyData.get('keyResultId'),
              Target__c = (Decimal) surveyData.get('target'),
              Completed_Target__c = (Decimal) surveyData.get('completedTarget')
          );
  
          insert newSurvey;
      }
      
      @AuraEnabled
      public static void createLead(Map<String, Object> leadData) {

          // Create a new Lead target

          CustomLead__c newLead = new CustomLead__c(
              Name = (String) leadData.get('leadName'),
              Key_Result__c = (String) leadData.get('keyResultId'),
              Target__c = (Decimal) leadData.get('target'),
              Completed_Target__c = (Decimal) leadData.get('completedTarget')
          );
  
          insert newLead;
      }

        @AuraEnabled
        public static void createOpportunity(Map<String, Object> opportunityData) {

            // Create a new Opportunity target

            CustomOpportunity__c newOpportunity = new CustomOpportunity__c(
                Name = (String) opportunityData.get('opportunityName'),
                Type__c = (String) opportunityData.get('opportunityType'),
                Target__c = (Decimal) opportunityData.get('target'),
                Completed_Target__c = (Decimal) opportunityData.get('completedTarget'),
                Key_Result__c = (String) opportunityData.get('keyResultId')
            );
    
            insert newOpportunity;
        }

        @AuraEnabled
        public static void createContract(Map<String, Object> contractData) {

            // Create a new Contract target

            CustomContract__c newContract = new CustomContract__c(
                Name = (String) contractData.get('contractName'),
                Type__c = (String) contractData.get('contractType'),
                Target__c = (Decimal) contractData.get('target'),
                Completed_Target__c = (Decimal) contractData.get('completedTarget')
            );
    
            insert newContract;
        }
    

      @AuraEnabled(cacheable=true)
      public static List<PicklistEntry> getPicklistValues(String objectApiName, String fieldApiName) {
          Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().get(fieldApiName).getDescribe();
          List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
          List<PicklistEntry> entries = new List<PicklistEntry>();
          for (Schema.PicklistEntry entry : picklistEntries) {
              entries.add(new PicklistEntry(entry.getLabel(), entry.getValue()));
          }
          return entries;
      }
  
      public class PicklistEntry {
          @AuraEnabled
          public String label { get; set; }
          @AuraEnabled
          public String value { get; set; }
  
          public PicklistEntry(String label, String value) {
              this.label = label;
              this.value = value;
          }
      }
  
  
      
      // Fetch active users

      @AuraEnabled(cacheable=true)
      public static List<User> getActiveUsers() {
          return [SELECT Id, Name FROM User WHERE IsActive = TRUE];
      }
  
      // Create a new Objective

      @AuraEnabled
      public static void createObjective(Objective__c obj) {
          if (obj != null) {

              // Check if the user has access to the necessary fields

              if (Schema.sObjectType.Objective__c.fields.Name.isAccessible() &&
                  Schema.sObjectType.Objective__c.fields.Objective_Year__c.isAccessible() &&
                  Schema.sObjectType.Objective__c.fields.Assigned_User__c.isAccessible() &&
                  Schema.sObjectType.Objective__c.fields.Status__c.isAccessible()) {
                  try {
                      insert obj;
                  } catch (DmlException e) {
                      throw new AuraHandledException('Error inserting Objective: ' + e.getMessage());
                  }
              } else {
                  throw new AuraHandledException('Field-level security issues detected.');
              }
          } else {
              throw new AuraHandledException('Objective data is invalid.');
          }
      }
  
      // Create a new Key Result associated with an Objective

  @AuraEnabled
  public static void createKeyResult(Key_Result__c kr, List<Call__c> calls, List<Event> events) {
      if (kr != null) {

          // Check if the user has access to the necessary fields

          if (Schema.sObjectType.Key_Result__c.fields.Name.isAccessible()) {
              try {
                  insert kr;
  
                  // Link each call to the newly created Key Result

                  for (Call__c call : calls) {
                      call.Key_Result__c = kr.Id;
                  }
                  
                  // Insert the list of Call__c records

                  if (!calls.isEmpty()) {
                      insert calls;
                  }
                  
                  // Link each event to the newly created Key Result

                  for (Event evt : events) {
                      evt.WhatId = kr.Id; // Set the Key Result Id as the WhatId
                  }
                  
                  // Insert the list of Event records

                  if (!events.isEmpty()) {
                      insert events;
                  }
              } catch (DmlException e) {
                  throw new AuraHandledException('Error inserting Key Result, Calls, or Events: ' + e.getMessage());
              }
          } else {
              throw new AuraHandledException('Field-level security issues detected.');
          }
      } else {
          throw new AuraHandledException('Key Result data is invalid.');
      }
  }
  
  @AuraEnabled
public static void createCall(Map<String, Object> callData) {

            // Create a new Call target

    Call__c newCall = new Call__c(
        Name = (String) callData.get('callName'),
        Key_Result__c = (String) callData.get('keyResultId'),
        Target__c = (Decimal) callData.get('target'),
        Completed_Target__c = (Decimal) callData.get('completedTarget')
    );

    insert newCall;
}

@AuraEnabled
        public static void createCustomEvent(Map<String, Object> customEventData) {
            // Create a new Event target
            CustomEvent__c newCustomEvent = new CustomEvent__c(
                Name = (String) customEventData.get('customEventName'),
                Key_Result__c = (String) customEventData.get('keyResultId'),
                Target__c = (Decimal) customEventData.get('target'),
                Completed_Target__c = (Decimal) customEventData.get('completedTarget')
            );
    
            insert newCustomEvent;
        }
  

      @AuraEnabled
public static void createCaseStudy(Map<String, Object> caseStudyData) {
            // Create a new Case Study target
    Case_Study__c newCaseStudy = new Case_Study__c(
        Name = (String) caseStudyData.get('caseStudyName'),
        Key_Result__c = (String) caseStudyData.get('keyResultId'),
        Target__c = (Decimal) caseStudyData.get('target'),
        Completed_Target__c = (Decimal) caseStudyData.get('completedTarget')
    );

    insert newCaseStudy;
}

      @AuraEnabled
public static void createGoogleReview(Map<String, Object> googleReviewData) {

    // Create a new Google Review target

    Google_Review__c newGoogleReview = new Google_Review__c(
        Name = (String) googleReviewData.get('googleReviewName'),
        Key_Result__c = (String) googleReviewData.get('keyResultId'),
        Target__c = (Decimal) googleReviewData.get('target'),
        Completed_Target__c = (Decimal) googleReviewData.get('completedTarget')
    );

    insert newGoogleReview;
}
  
      // Relate a record to a Key Result

      @AuraEnabled
      public static void relateRecord(String keyResultId, String recordId, String recordType) {
          if (String.isBlank(keyResultId) || String.isBlank(recordId) || String.isBlank(recordType)) {
              throw new AuraHandledException('Invalid input parameters.');
          }
  
          SObject relatedRecord;
  
          // Determine the type of record and set the Key_Result__c field
          
          if (recordType == 'Event') {
              Event eventRecord = [SELECT Id, WhatId FROM Event WHERE Id = :recordId LIMIT 1];
              if (Schema.sObjectType.Event.fields.WhatId.isAccessible()) {
                  eventRecord.WhatId = keyResultId;
                  relatedRecord = eventRecord;
              } else {
                  throw new AuraHandledException('Field-level security issues detected.');
              }
          } else if (recordType == 'CustomContract__c') {
              CustomContract__c contractRecord = [SELECT Id, Key_Result__c FROM CustomContract__c WHERE Id = :recordId LIMIT 1];
              if (Schema.sObjectType.CustomContract__c.fields.Key_Result__c.isAccessible()) {
                  contractRecord.Key_Result__c = keyResultId;
                  relatedRecord = contractRecord;
              } else {
                  throw new AuraHandledException('Field-level security issues detected.');
              }
          } else if (recordType == 'CustomOpportunity__c') {
              CustomOpportunity__c oppRecord = [SELECT Id, Key_Result__c FROM CustomOpportunity__c WHERE Id = :recordId LIMIT 1];
              if (Schema.sObjectType.CustomOpportunity__c.fields.Key_Result__c.isAccessible()) {
                  oppRecord.Key_Result__c = keyResultId;
                  relatedRecord = oppRecord;
              } else {
                  throw new AuraHandledException('Field-level security issues detected.');
              }
          } else {
              throw new AuraHandledException('Unknown record type.');
          }
  
          try {
              update relatedRecord;
          } catch (DmlException e) {
              throw new AuraHandledException('Error relating record: ' + e.getMessage());
          }
      }
  }
  