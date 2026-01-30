// src/components/TransformGridItem.tsx

import { useEffect, useState } from "react";
import clsx from "clsx";
import style from "./styles.module.css";

export const TransformGridItem = ({ transform, value, setValue }) => {
  const [options, setOptions] = useState(transform.options);
  const [closedToggle, setClosedToggle] = useState(false);
  const [result, setResult] = useState({
    error: false,
    value: "",
  });

  const previewDisabled = value.length > 30000;
  const closed = previewDisabled || closedToggle;

  const triggerTransform = async () =>
    await transform
      .fn(value, options)
      .then((result) => {
        setResult(result);
        return result;
      })
      .catch((error) => {
        setResult({ error: true, value: error.toString() });
        return { error: true, value: error.toString() };
      });

  // Trigger transform when value, option or closed state changes
  useEffect(() => {
    if (previewDisabled) return;

    transform
      .fn(value, options)
      .then(setResult.bind(this))
      .catch((error) => setResult({ error: true, value: error.toString() }));
  }, [value, options, closed, previewDisabled, transform]);

  // Reset error state when options change
  useEffect(() => {
    if (!previewDisabled) return;

    setResult({
      error: false,
      value: "",
    });
  }, [options, previewDisabled]);

  // Force disable preview when value is longer than 30,000 chars
  useEffect(() => {
    if (previewDisabled) {
      setResult({
        error: false,
        value: "",
      });
      return;
    }

    transform
      .fn(value, options)
      .then(setResult.bind(this))
      .catch((error) => setResult({ error: true, value: error.toString() }));
  }, [value, previewDisabled, transform, options]);

  const onCheckboxOptionChanged = (option) => (event) => {
    options.set(option.key, {
      ...option,
      value: event.target.checked,
    });

    setOptions(new Map(options));
  };

  const onTextboxOptionChanged = (option) => (event) => {
    options.set(option.key, {
      ...option,
      value: event.target.value,
    });

    setOptions(new Map(options));
  };

  const onIntboxOptionChanged = (option) => (event) => {
    options.set(option.key, {
      ...option,
      value: parseInt(event.target.value),
    });

    setOptions(new Map(options));
  };

  const onRadioOptionChanged = (option) => (event) => {
    options.set(option.key, {
      ...option,
      value: event.target.value,
    });

    setOptions(new Map(options));
  };

  const onForwardButtonPressed = async () => {
    const result = await triggerTransform();

    if (result.error) return;

    setValue(result.value);
  };

  const onLabelClicked = async () => {
    if (previewDisabled) return;

    setClosedToggle(!closed);
  };

  return (
    <div className={clsx(style.item, closed && style.closed)}>
      <div className={style.toolbar}>
        <div data-tooltip-id={`${transform.name}-tooltip`}>
          <button disabled={result.error} onClick={onForwardButtonPressed}>
            &lt;&lt;&lt;
          </button>
        </div>

        <p
          className={style.error}
          id={`${transform.name}-tooltip`}
          place="bottom"
        >
          {previewDisabled && result.error && result.value}
        </p>

        <h2
          onClick={onLabelClicked}
          className={clsx(style.name, previewDisabled && style.previewDisabled)}
        >
          {transform.name}
        </h2>

        <div className={style.options}>
          {[...options.values()]
            ?.filter((v) => v.type === "CHECKBOX")
            .map((option, i) => (
              <label key={i} className={style.optionItem}>
                <p>{option.label ?? option.key}:</p>

                <input
                  checked={option.value}
                  onChange={onCheckboxOptionChanged(option)}
                  type="checkbox"
                />
              </label>
            ))}

          {[...options.values()]
            ?.filter((v) => v.type === "TEXTBOX")
            .map((option, i) => (
              <label key={i} className={style.optionItem}>
                <p>{option.label ?? option.key}:</p>

                <input
                  value={option.value}
                  onChange={onTextboxOptionChanged(option)}
                  type="text"
                />
              </label>
            ))}

          {[...options.values()]
            ?.filter((v) => v.type === "INTBOX")
            .map((option, i) => (
              <label key={i} className={style.optionItem}>
                <p>{option.label ?? option.key}:</p>

                <input
                  min={1}
                  value={option.value}
                  onChange={onIntboxOptionChanged(option)}
                  type="number"
                />
              </label>
            ))}

          {[...options.values()]
            ?.filter((v) => v.type === "RADIO")
            .map((option, i) => (
              <div
                key={i}
                onChange={onRadioOptionChanged(option)}
                className={style.optionItem}
              >
                {option.radios.map((radio, i2) => (
                  <label key={i2}>
                    <span>{radio.label ?? radio.value}:</span>

                    <input
                      min={1}
                      name={option.key}
                      defaultChecked={radio.value === option.value}
                      value={radio.value}
                      type="radio"
                    />
                  </label>
                ))}
              </div>
            ))}
        </div>
      </div>

      {!closed && (
        <div
          initial={{ height: 0 }}
          animate={{ height: 200 }}
          exit={{ height: 0 }}
          className={style.output}
        >
          <textarea
            readOnly
            value={result.value}
            placeholder="(empty)"
            className={clsx(result.error && style.error)}
          />
        </div>
      )}
    </div>
  );
};
