#include "MHReputationSubsystem.h"

void UMHReputationSubsystem::AddReputation(FGameplayTag FactionTag, int32 Delta)
{
    if (!FactionTag.IsValid() || Delta == 0)
    {
        return;
    }

    int32& Reputation = ReputationByFaction.FindOrAdd(FactionTag);
    Reputation = FMath::Clamp(Reputation + Delta, -100, 100);
}

int32 UMHReputationSubsystem::GetReputation(FGameplayTag FactionTag) const
{
    const int32* Reputation = ReputationByFaction.Find(FactionTag);
    return Reputation != nullptr ? *Reputation : 0;
}

bool UMHReputationSubsystem::MeetsReputation(FGameplayTag FactionTag, int32 RequiredValue) const
{
    return GetReputation(FactionTag) >= RequiredValue;
}
