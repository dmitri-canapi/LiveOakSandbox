trigger AssessmentTrigger on Assessment__c (after insert, after update) {

    if (AssessmentSharingService.RecalculateSharingOnAssessmentReviewerChange) {
        // build a list of assessments for which reviewer sharing should be recalculated
        List<Assessment__c> assessmentsToRecalcSharing = new List<Assessment__c>();
        for (Assessment__c assessment : Trigger.new) {
            if (Trigger.isInsert && assessment.Account_Reviewer__c != null) {
                assessmentsToRecalcSharing.add(assessment);
            }
            else if (Trigger.isUpdate) {
                Assessment__c oldAssessment = Trigger.oldMap.get(assessment.Id);
                if (assessment.Account_Reviewer__c != oldAssessment.Account_Reviewer__c) {
                    assessmentsToRecalcSharing.add(assessment);
                }
            }
        }

        // recalculate sharing
        if (!assessmentsToRecalcSharing.isEmpty()) {
            AssessmentSharingService.recalculateSharing(assessmentsToRecalcSharing);
        }
    }
}