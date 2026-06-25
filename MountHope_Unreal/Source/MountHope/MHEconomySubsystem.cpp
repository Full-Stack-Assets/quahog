#include "MHEconomySubsystem.h"

int32 UMHEconomySubsystem::GetCashBalance() const
{
    return CashBalance;
}

void UMHEconomySubsystem::AddCash(int32 Amount, FName Reason)
{
    if (Amount <= 0)
    {
        return;
    }

    CashBalance += Amount;
}

bool UMHEconomySubsystem::SpendCash(int32 Amount, FName Reason)
{
    if (Amount <= 0 || CashBalance < Amount)
    {
        return false;
    }

    CashBalance -= Amount;
    return true;
}
