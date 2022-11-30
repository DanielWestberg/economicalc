def check_type(value, expected_type, value_name=None):
    value_note = " "
    if value_name is not None:
        value_note += f"{value_name} to be "

    if type(expected_type) == list:
        value_note += "one of "
        should_raise = all([type(value) != t for t in expected_type])
    else:
        should_raise = type(value) != expected_type

    if should_raise:
        raise TypeError(f"Expected{value_note}{expected_type}, not {type(value)}")
