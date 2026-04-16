"""Backend package initialization."""

# Workaround for a Django BaseContext.__copy__ bug that breaks admin templates.
# This avoids AttributeError: 'super' object has no attribute 'dicts' on Python 3.14.
try:
    from django.template.context import BaseContext

    def _basecontext_copy(self):
        # Avoid calling __init__ of subclasses like RequestContext, which
        # require a request argument. Shallow-copy instance state instead.
        duplicate = self.__class__.__new__(self.__class__)
        duplicate.__dict__ = self.__dict__.copy()
        duplicate.dicts = self.dicts[:]
        return duplicate

    BaseContext.__copy__ = _basecontext_copy
except Exception:
    # If Django isn't available during import, skip patching.
    pass
