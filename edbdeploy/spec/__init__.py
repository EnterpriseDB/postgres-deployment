class SpecValidator:
    def __init__(self, type=None, default=None, choices=[], min=None,
                 max=None):
        self.type = type
        self.default = default
        self.choices = choices
        self.min = min
        self.max = max
