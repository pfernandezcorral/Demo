<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowActions>
        <fullName>Booking_Notification</fullName>
        <description>Trigger initiating Booking Notifications</description>
        <flow>LP_BookingTool_Notification</flow>
        <flowInputs>
            <name>BookingRecord</name>
            <value>{!this}</value>
        </flowInputs>
        <flowInputs>
            <name>CaseRecord</name>
            <value>{!LP_BT_Case__r}</value>
        </flowInputs>
        <flowInputs>
            <name>ContactRecord</name>
            <value>{!LP_BT_Driver__r}</value>
        </flowInputs>
        <label>Booking Notification</label>
        <language>en_US</language>
        <protected>false</protected>
    </flowActions>
    <rules>
        <fullName>Booking Confirmation Garage</fullName>
        <actions>
            <name>Booking_Notification</name>
            <type>FlowAction</type>
        </actions>
        <active>true</active>
        <description>Initiating a flow for the Booking notifications</description>
        <formula>OR(  ISCHANGED(LP_BT_BookingStatus__c),   ISNEW(),   AND(   ISPICKVAL(LP_BT_BookingStatus__c, &apos;Unconfirmed&apos;),    ISCHANGED(LP_ResponseLimitTimeBreached__c),   LP_ResponseLimitTimeBreached__c = TRUE  ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
