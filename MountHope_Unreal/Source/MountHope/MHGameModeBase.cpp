#include "MHGameModeBase.h"

#include "MHPlayerCharacter.h"

AMHGameModeBase::AMHGameModeBase()
{
    DefaultPawnClass = AMHPlayerCharacter::StaticClass();
}
