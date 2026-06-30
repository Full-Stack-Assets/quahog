#include "MHGameModeBase.h"

#include "MHGameStateSubsystem.h"
#include "MHMissionSubsystem.h"
#include "MHMissionTriggerActor.h"
#include "MHPlayerCharacter.h"

AMHGameModeBase::AMHGameModeBase()
{
    PrimaryActorTick.bCanEverTick = true;
    DefaultPawnClass = AMHPlayerCharacter::StaticClass();
}

void AMHGameModeBase::BeginPlay()
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

    RefreshObjectiveTrigger();
}

void AMHGameModeBase::Tick(float DeltaSeconds)
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

bool AMHGameModeBase::CompleteCurrentObjective(bool bPlayerInVehicle)
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

    GameStateSubsystem->SaveToSlot();
    RefreshObjectiveTrigger();
    return bAdvanced;
}

bool AMHGameModeBase::TryCompleteVehicleObjective(bool bPlayerInVehicle)
{
    if (!GetGameInstance())
    {
        return false;
    }

    UMHMissionSubsystem* MissionSubsystem = GetGameInstance()->GetSubsystem<UMHMissionSubsystem>();
    if (!MissionSubsystem)
    {
        return false;
    }

    FMHMissionStep Step;
    if (!MissionSubsystem->GetCurrentStep(Step))
    {
        return false;
    }

    if (Step.bNeedVehicle == bPlayerInVehicle && !IsWorldTargetObjective(Step))
    {
        return CompleteCurrentObjective(bPlayerInVehicle);
    }

    return false;
}

bool AMHGameModeBase::IsWorldTargetObjective(const FMHMissionStep& Step) const
{
    return Step.Radius > UE_KINDA_SMALL_NUMBER;
}

void AMHGameModeBase::RefreshObjectiveTrigger()
{
    if (!GetWorld() || !GetGameInstance())
    {
        return;
    }

    UMHMissionSubsystem* MissionSubsystem = GetGameInstance()->GetSubsystem<UMHMissionSubsystem>();
    if (!MissionSubsystem)
    {
        return;
    }

    FMHMissionStep Step;
    const bool bHasStep = MissionSubsystem->GetCurrentStep(Step);
    const bool bNeedsTrigger = bHasStep && IsWorldTargetObjective(Step);

    if (!bNeedsTrigger)
    {
        if (ObjectiveTrigger)
        {
            ObjectiveTrigger->SetActorEnableCollision(false);
            ObjectiveTrigger->SetActorHiddenInGame(true);
        }
        return;
    }

    if (!ObjectiveTrigger)
    {
        ObjectiveTrigger = GetWorld()->SpawnActor<AMHMissionTriggerActor>(
            AMHMissionTriggerActor::StaticClass(),
            Step.Target,
            FRotator::ZeroRotator);
    }

    if (!ObjectiveTrigger)
    {
        return;
    }

    ObjectiveTrigger->SetTriggerRadius(Step.Radius);
    ObjectiveTrigger->SetActorLocation(Step.Target);
    ObjectiveTrigger->SetActorEnableCollision(true);
    ObjectiveTrigger->SetActorHiddenInGame(false);
    ObjectiveTrigger->ResetConsumed();
}
