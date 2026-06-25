#include "MountHopeCharacter.h"

#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "EngineUtils.h"
#include "GameFramework/Controller.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "InputAction.h"
#include "InputActionValue.h"
#include "MountHopeGameMode.h"
#include "MountHopeVehiclePawn.h"
#include "GameFramework/PlayerController.h"

AMountHopeCharacter::AMountHopeCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
}

void AMountHopeCharacter::BeginPlay()
{
    Super::BeginPlay();

    if (APlayerController* PC = Cast<APlayerController>(Controller))
    {
        if (ULocalPlayer* LocalPlayer = PC->GetLocalPlayer())
        {
            if (UEnhancedInputLocalPlayerSubsystem* InputSubsystem =
                LocalPlayer->GetSubsystem<UEnhancedInputLocalPlayerSubsystem>())
            {
                if (DefaultMappingContext)
                {
                    InputSubsystem->AddMappingContext(DefaultMappingContext, 0);
                }
            }
        }
    }
}

void AMountHopeCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    if (APlayerController* PC = Cast<APlayerController>(Controller))
    {
        if (ULocalPlayer* LocalPlayer = PC->GetLocalPlayer())
        {
            if (UEnhancedInputLocalPlayerSubsystem* InputSubsystem =
                LocalPlayer->GetSubsystem<UEnhancedInputLocalPlayerSubsystem>())
            {
                if (DefaultMappingContext)
                {
                    InputSubsystem->AddMappingContext(DefaultMappingContext, 0);
                }
            }
        }
    }

    UEnhancedInputComponent* EnhancedInput = Cast<UEnhancedInputComponent>(PlayerInputComponent);
    if (!EnhancedInput)
    {
        return;
    }

    if (IA_Move)
    {
        EnhancedInput->BindAction(IA_Move, ETriggerEvent::Triggered, this, &AMountHopeCharacter::InputMove);
    }
    if (IA_Look)
    {
        EnhancedInput->BindAction(IA_Look, ETriggerEvent::Triggered, this, &AMountHopeCharacter::InputLook);
    }
    if (IA_Sprint)
    {
        EnhancedInput->BindAction(IA_Sprint, ETriggerEvent::Started, this, &AMountHopeCharacter::InputSprintStart);
        EnhancedInput->BindAction(IA_Sprint, ETriggerEvent::Completed, this, &AMountHopeCharacter::InputSprintStop);
        EnhancedInput->BindAction(IA_Sprint, ETriggerEvent::Canceled, this, &AMountHopeCharacter::InputSprintStop);
    }
    if (IA_Interact)
    {
        EnhancedInput->BindAction(IA_Interact, ETriggerEvent::Started, this, &AMountHopeCharacter::InputInteract);
    }
}

void AMountHopeCharacter::SetSprinting(bool bEnableSprint)
{
    GetCharacterMovement()->MaxWalkSpeed = bEnableSprint ? SprintSpeed : WalkSpeed;
}

bool AMountHopeCharacter::EnterVehicle(AMountHopeVehiclePawn* VehiclePawn)
{
    if (bInVehicle || !VehiclePawn || !Controller)
    {
        return false;
    }

    CurrentVehicle = VehiclePawn;
    bInVehicle = true;

    SetActorEnableCollision(false);
    SetActorHiddenInGame(true);
    Controller->Possess(VehiclePawn);

    if (AMountHopeGameMode* GameMode = GetWorld() ? Cast<AMountHopeGameMode>(GetWorld()->GetAuthGameMode()) : nullptr)
    {
        GameMode->TryCompleteVehicleObjective(true);
    }

    return true;
}

bool AMountHopeCharacter::ExitVehicle()
{
    if (!bInVehicle || !CurrentVehicle || !Controller)
    {
        return false;
    }

    const FVector ExitLocation = CurrentVehicle->GetSuggestedExitLocation();
    SetActorLocation(ExitLocation);
    SetActorEnableCollision(true);
    SetActorHiddenInGame(false);
    Controller->Possess(this);

    bInVehicle = false;
    CurrentVehicle = nullptr;
    return true;
}

void AMountHopeCharacter::InputMove(const FInputActionValue& Value)
{
    if (bInVehicle)
    {
        return;
    }

    const FVector2D Axis = Value.Get<FVector2D>();
    if (!Axis.IsNearlyZero())
    {
        AddMovementInput(GetActorForwardVector(), Axis.Y);
        AddMovementInput(GetActorRightVector(), Axis.X);
    }
}

void AMountHopeCharacter::InputLook(const FInputActionValue& Value)
{
    const FVector2D Axis = Value.Get<FVector2D>();
    if (!Axis.IsNearlyZero())
    {
        AddControllerYawInput(Axis.X);
        AddControllerPitchInput(Axis.Y);
    }
}

void AMountHopeCharacter::InputSprintStart(const FInputActionValue& Value)
{
    SetSprinting(true);
}

void AMountHopeCharacter::InputSprintStop(const FInputActionValue& Value)
{
    SetSprinting(false);
}

void AMountHopeCharacter::InputInteract(const FInputActionValue& Value)
{
    if (bInVehicle)
    {
        ExitVehicle();
        return;
    }

    if (AMountHopeVehiclePawn* NearbyVehicle = FindNearestVehicle())
    {
        EnterVehicle(NearbyVehicle);
    }
}

AMountHopeVehiclePawn* AMountHopeCharacter::FindNearestVehicle() const
{
    if (!GetWorld())
    {
        return nullptr;
    }

    AMountHopeVehiclePawn* BestVehicle = nullptr;
    float BestDistSq = VehicleInteractRange * VehicleInteractRange;
    const FVector MyLoc = GetActorLocation();

    for (TActorIterator<AMountHopeVehiclePawn> It(GetWorld()); It; ++It)
    {
        AMountHopeVehiclePawn* Candidate = *It;
        if (!IsValid(Candidate))
        {
            continue;
        }

        const float DistSq = FVector::DistSquared(MyLoc, Candidate->GetActorLocation());
        if (DistSq <= BestDistSq)
        {
            BestDistSq = DistSq;
            BestVehicle = Candidate;
        }
    }

    return BestVehicle;
}
