public without sharing class AssessmentSharingService {
    public static Boolean RecalculateSharingOnAssessmentReviewerChange = true;
    public static Boolean RecalculateSharingOnCommunityUserCreation = true;

    public static void recalculateSharing(List<Assessment__c> assessments) {
        // build assessment and reviewer account id sets
        Set<Id> assessmentIds = new Set<Id>();
        Set<Id> assessmentReviewerIds = new Set<Id>();
        for (Assessment__c assessment : assessments) {
            assessmentIds.add(assessment.Id);
            if (assessment.Account_Reviewer__c != null) {
                assessmentReviewerIds.add(assessment.Account_Reviewer__c);
            }
        }

        System.debug('*** ' + assessmentReviewerIds);

        // get current manual sharing records for assessments
        List<Assessment__Share> shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE ParentId IN :assessmentIds
            AND RowCause = 'Manual'
            ORDER BY ParentId
        ];

        // delete them
        if (!shares.isEmpty()) {
            delete shares;
        }

        // build map of reviewer accounts and users
        Map<Id, Set<Id>> accountIdUserIdMap = new Map<Id, Set<Id>>();
        for (User u : [
                SELECT Id, AccountId 
                FROM User 
                WHERE AccountId  IN : assessmentReviewerIds
                ORDER BY AccountId  ]) {
            
            if (!accountIdUserIdMap.containsKey(u.AccountId)) {
                accountIdUserIdMap.put(u.AccountId, new Set<Id>());
            }
            accountIdUserIdMap.get(u.AccountId).add(u.Id);
        }

        // build a list of manual sharing records to add
        List<Assessment__Share> newShares = new List<Assessment__Share>();
        for (Assessment__c assessment : assessments) {
            if (assessment.Account_Reviewer__c != null && accountIdUserIdMap.containsKey(assessment.Account_Reviewer__c)) {
                for (Id userId : accountIdUserIdMap.get(assessment.Account_Reviewer__c)) {
                    newShares.add(new Assessment__Share(AccessLevel = 'Edit', ParentId = assessment.Id, UserOrGroupId = userId));
                }
            }
        }

        // insert them
        if (!newShares.isEmpty()) {
            insert newShares;
        }
    }

    @future
    public static void recalculateSharingFuture(List<Id> userIds) {
        List<User> users = [
            SELECT Id, AccountId, ContactId 
            FROM User 
            WHERE Id IN :userIds
        ];

        recalculateSharing(users);
    }

    public static void recalculateSharing(List<User> users) {
        // build map of accounts and users
        Map<Id, Set<Id>> accountIdUserIdMap = new Map<Id, Set<Id>>();
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            if (u.AccountId != null) {
                if (!accountIdUserIdMap.containsKey(u.AccountId)) {
                    accountIdUserIdMap.put(u.AccountId, new Set<Id>());
                }
                accountIdUserIdMap.get(u.AccountId).add(u.Id);
                userIds.add(u.Id);
            }
        }

        if (!userIds.isEmpty()) {
            // get current manual assessment sharing records for users
            List<Assessment__Share> shares = [
                SELECT AccessLevel, ParentId, UserOrGroupId
                FROM Assessment__Share
                WHERE UserOrGroupId IN :userIds
                AND RowCause = 'Manual'
                ORDER BY ParentId
            ];

            // delete them
            if (!shares.isEmpty()) {
                delete shares;
            }

            // build a list of manual sharing records to add
            List<Assessment__Share> newShares = new List<Assessment__Share>();
            for (Assessment__c assessment : [
                    SELECT Id, Account_Reviewer__c
                    FROM Assessment__c
                    WHERE Account_Reviewer__c IN : accountIdUserIdMap.keySet() ]) {

                for (Id userId : accountIdUserIdMap.get(assessment.Account_Reviewer__c)) {
                    newShares.add(new Assessment__Share(AccessLevel = 'Edit', ParentId = assessment.Id, UserOrGroupId = userId));
                }
            }

            // insert them
            if (!newShares.isEmpty()) {
                insert newShares;
            }
        }
    }
}