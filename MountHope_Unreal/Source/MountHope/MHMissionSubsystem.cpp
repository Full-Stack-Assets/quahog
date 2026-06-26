#include "MHMissionSubsystem.h"

bool UMHMissionSubsystem::StartMission(FGameplayTag MissionTag)
{
    if (!MissionTag.IsValid() || CompletedMissions.HasTagExact(MissionTag))
    {
        return false;
    }

    ActiveMissions.AddTag(MissionTag);
    return true;
}

bool UMHMissionSubsystem::CompleteMission(FGameplayTag MissionTag)
{
    if (!MissionTag.IsValid() || !ActiveMissions.HasTagExact(MissionTag))
    {
        return false;
    }

    ActiveMissions.RemoveTag(MissionTag);
    CompletedMissions.AddTag(MissionTag);
    return true;
}

bool UMHMissionSubsystem::IsMissionActive(FGameplayTag MissionTag) const
{
    return ActiveMissions.HasTagExact(MissionTag);
}

bool UMHMissionSubsystem::IsMissionComplete(FGameplayTag MissionTag) const
{
    return CompletedMissions.HasTagExact(MissionTag);
}
