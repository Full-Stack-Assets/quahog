#include "MountHopeGameMode.h"

#include "MHGameStateSubsystem.h"
#include "MHMissionSubsystem.h"
#include "MountHopeCharacter.h"

AMountHopeGameMode::AMountHopeGameMode()
{
    PrimaryActorTick.bCanEverTick = true;
    DefaultPawnClass = AMountHopeCharacter::StaticClass();
}

void AMountHopeGameMode::BeginPlay()
{
    Super::BeginPlay();

    if (!GetGameInstance())
    {
        return;
    }

    UMHMissionSubsystem* MissionSubsystem = GetGameInstance()->GetSubsystem<UMHMissionSubsystem>();
    FMHMissionStep Step;
    if (MissionSubsystem && MissionSubsystem->GetCurrentStep(Step))
    {
        UE_LOG(LogTemp, Log, TEXT("MountHope: Objective -> %s"), *Step.Text);
    }
}

void AMountHopeGameMode::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (!GetGameInstance())
    {
        return;
    }

    if (UMHGameStateSubsystem* GameStateSubsystem = GetGameInstance()->GetSubsystem<UMHGameStateSubsystem>())
    {
        GameStateSubsystem->DecayHeat(DeltaSeconds);
    }
}

bool AMountHopeGameMode::CompleteCurrentObjective(bool bPlayerInVehicle)
{
    if (!GetGameInstance())
    {
        return false;
    }

    UMHMissionSubsystem* MissionSubsystem = GetGameInstance()->GetSubsystem<UMHMissionSubsystem>();
    UMHGameStateSubsystem* GameStateSubsystem = GetGameInstance()->GetSubsystem<UMHGameStateSubsystem>();
    if (!MissionSubsystem || !GameStateSubsystem)
    {
        return false;
    }

    FMHMissionStep Step;
    if (!MissionSubsystem->GetCurrentStep(Step))
    {
        return false;
    }

    if (Step.bNeedVehicle && !bPlayerInVehicle)
    {
        UE_LOG(LogTemp, Warning, TEXT("MountHope: objective requires vehicle."));
        return false;
    }

    if (Step.Reward > 0)
    {
        GameStateSubsystem->AddCash(Step.Reward);
    }

    const bool bAdvanced = MissionSubsystem->AdvanceStep();
    FMHMissionStep NextStep;
    if (bAdvanced && MissionSubsystem->GetCurrentStep(NextStep))
    {
        UE_LOG(LogTemp, Log, TEXT("MountHope: Next objective -> %s"), *NextStep.Text);
    }
    return bAdvanced;
}
