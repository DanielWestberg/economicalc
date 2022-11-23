def check_type(value, expected_type, value_name=None):
    if type(value) != expected_type:
        value_note = f" {value_name} to be " if value_name is not None else ""
        raise TypeError(f"Expected{value_note}{expected_type}, not {type(value)}")
