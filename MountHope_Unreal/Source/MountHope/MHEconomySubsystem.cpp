#include "MHEconomySubsystem.h"

#include "MHGameStateSubsystem.h"

int32 UMHEconomySubsystem::GetCashBalance() const
{
    if (const UMHGameStateSubsystem* GameState = GetGameInstance()
        ? GetGameInstance()->GetSubsystem<UMHGameStateSubsystem>()
        : nullptr)
    {
        return GameState->Cash;
    }

    return 0;
}

void UMHEconomySubsystem::AddCash(int32 Amount, FName Reason)
{
    if (Amount <= 0)
    {
        return;
    }

    if (UMHGameStateSubsystem* GameState = GetGameInstance()
        ? GetGameInstance()->GetSubsystem<UMHGameStateSubsystem>()
        : nullptr)
    {
        GameState->AddCash(Amount);
    }
}

bool UMHEconomySubsystem::SpendCash(int32 Amount, FName Reason)
{
    if (Amount <= 0)
    {
        return false;
    }

    UMHGameStateSubsystem* GameState = GetGameInstance()
        ? GetGameInstance()->GetSubsystem<UMHGameStateSubsystem>()
        : nullptr;
    if (!GameState || GameState->Cash < Amount)
    {
        return false;
    }

    GameState->AddCash(-Amount);
    return true;
}
